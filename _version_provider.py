"""
Dynamic version provider for halide-llvm.

This provider does double duty:
1. Downloads LLVM source from GitHub based on HALIDE_LLVM_REF
2. Returns a PEP 440 version string

Environment variables:
  HALIDE_LLVM_REF   - Required. Git ref (tag, branch, or commit SHA)
  GITHUB_TOKEN      - Optional. Avoids rate limiting in CI
"""

from __future__ import annotations

import io
import json
import os
import re
import shutil
import tarfile
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

# --- Configuration ---
CACHE_ROOT = Path(__file__).parent / "src_cache"
LLVM_REPO_OWNER = "llvm"
LLVM_REPO_NAME = "llvm-project"


def dynamic_metadata(
    field: str,
    settings: Mapping[str, Any] | None = None,
) -> str:
    """scikit-build-core dynamic metadata hook."""
    if field != "version":
        msg = f"Only 'version' is supported, not {field!r}"
        raise RuntimeError(msg)

    ref = os.environ.get("HALIDE_LLVM_REF")
    if not ref:
        msg = (
            "Environment variable 'HALIDE_LLVM_REF' is required.\n"
            "Examples: 'llvmorg-21.1.6', 'main', or a commit SHA"
        )
        raise RuntimeError(msg)

    # 1. Prepare cache path
    safe_ref = sanitize_ref_for_path(ref)
    source_dir = CACHE_ROOT / safe_ref

    # 2. Download source if not cached
    commit_sha = None
    if not source_dir.exists():
        commit_sha = download_and_extract(ref, source_dir)
    else:
        print(f"[provider] Using cached source: {source_dir}")

    # 3. Compute version
    version = compute_version(ref, source_dir, commit_sha)
    print(f"[provider] Resolved version: {version}")
    return version


def sanitize_ref_for_path(ref: str) -> str:
    """
    Sanitizes a git ref to be safe for directory names.
    Must match the logic in CMakeLists.txt.
    """
    return re.sub(r'[\\/:*?"<>|]', "_", ref)


def compute_version(ref: str, source_dir: Path, commit_sha: str | None) -> str:
    """
    Compute PEP 440 version string.

    - Release tags (llvmorg-X.Y.Z) -> X.Y.Z
    - Everything else -> X.Y.Z.devYYYYMMDDHHMM+g<sha>
    """
    # Check for release tag pattern
    tag_match = re.match(r"^llvmorg-(\d+\.\d+\.\d+)$", ref)
    if tag_match:
        return tag_match.group(1)

    # Development version: need base version, timestamp, and SHA
    base_ver = get_base_version(source_dir)

    # Get commit info from GitHub API
    timestamp, sha = get_commit_info(ref)
    if commit_sha:
        sha = commit_sha  # Use SHA from download if available

    short_sha = sha[:8] if sha else "unknown"
    return f"{base_ver}.dev{timestamp}+g{short_sha}"


def get_base_version(source_dir: Path) -> str:
    """Parse Major.Minor.Patch from llvm/CMakeLists.txt."""
    cmake_path = source_dir / "llvm" / "CMakeLists.txt"
    if not cmake_path.exists():
        print(f"[provider] Warning: {cmake_path} not found, using 0.0.0")
        return "0.0.0"

    content = cmake_path.read_text(encoding="utf-8")
    major = re.search(r"set\(LLVM_VERSION_MAJOR\s+(\d+)\)", content)
    minor = re.search(r"set\(LLVM_VERSION_MINOR\s+(\d+)\)", content)
    patch = re.search(r"set\(LLVM_VERSION_PATCH\s+(\d+)\)", content)

    if major and minor and patch:
        return f"{major.group(1)}.{minor.group(1)}.{patch.group(1)}"

    print("[provider] Warning: Could not parse LLVM version, using 0.0.0")
    return "0.0.0"


def get_commit_info(ref: str) -> tuple[str, str]:
    """
    Fetch commit timestamp and SHA from GitHub API.
    Returns (timestamp_str, sha) where timestamp_str is YYYYMMDDHHMM.
    """
    url = f"https://api.github.com/repos/{LLVM_REPO_OWNER}/{LLVM_REPO_NAME}/commits/{ref}"
    req = urllib.request.Request(url)
    req.add_header("User-Agent", "halide-llvm-version-provider")

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"token {token}")

    print(f"[provider] Fetching commit info for '{ref}'...")

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.load(response)

        iso_date = data["commit"]["committer"]["date"]
        dt = datetime.strptime(iso_date, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
        timestamp = dt.strftime("%Y%m%d%H%M")
        sha = data["sha"]
        return timestamp, sha

    except (urllib.error.HTTPError, urllib.error.URLError, KeyError) as e:
        print(f"[provider] Warning: Could not fetch commit info ({e}), using fallback")
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M")
        return timestamp, "unknown"


def download_and_extract(ref: str, dest_dir: Path) -> str | None:
    """
    Download tarball from GitHub and extract to dest_dir.
    Returns the commit SHA if available.
    """
    # GitHub tarball URLs to try (tag URL first, then generic)
    urls = [
        f"https://github.com/{LLVM_REPO_OWNER}/{LLVM_REPO_NAME}/archive/refs/tags/{ref}.tar.gz",
        f"https://github.com/{LLVM_REPO_OWNER}/{LLVM_REPO_NAME}/archive/{ref}.tar.gz",
    ]

    # Use a temp directory for atomic extraction
    temp_dir = dest_dir.with_name(f".{dest_dir.name}_temp")
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    temp_dir.mkdir(parents=True)

    tarball_data = None
    for url in urls:
        try:
            print(f"[provider] Downloading {url}...")
            req = urllib.request.Request(url)
            req.add_header("User-Agent", "halide-llvm-version-provider")

            with urllib.request.urlopen(req, timeout=600) as response:
                # Read entire tarball into memory to avoid streaming issues
                tarball_data = response.read()
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"[provider] Not found at {url}, trying next...")
                continue
            raise RuntimeError(f"Download failed: {e}") from e

    if tarball_data is None:
        shutil.rmtree(temp_dir)
        raise RuntimeError(f"Could not download ref '{ref}' from GitHub.")

    # Extract tarball
    print(f"[provider] Extracting ({len(tarball_data) // 1024 // 1024} MB)...")
    with tarfile.open(fileobj=io.BytesIO(tarball_data), mode="r:gz") as tar:
        tar.extractall(path=temp_dir)

    # GitHub tarballs have a single root directory like 'llvm-project-<ref>/'
    extracted_roots = [p for p in temp_dir.iterdir() if p.is_dir()]
    if not extracted_roots:
        shutil.rmtree(temp_dir)
        raise RuntimeError("Tarball appeared empty or invalid.")

    # Move inner content to final destination
    actual_root = extracted_roots[0]
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    shutil.move(str(actual_root), str(dest_dir))
    shutil.rmtree(temp_dir)

    print(f"[provider] Extracted to {dest_dir}")

    # Try to extract SHA from the directory name (llvm-project-<sha>)
    # This works for commit SHAs but not for tags/branches
    root_name = actual_root.name
    sha_match = re.search(r"llvm-project-([a-f0-9]{40})", root_name)
    if sha_match:
        return sha_match.group(1)

    return None
