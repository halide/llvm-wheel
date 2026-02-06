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

import json
import os
import re
import shutil
import tarfile
import urllib.error
import urllib.request
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
    if not is_valid_cached_source(source_dir):
        if source_dir.exists():
            print(f"[provider] Invalid cache detected, removing: {source_dir}")
            shutil.rmtree(source_dir)
        download_and_extract(ref, source_dir)
    else:
        print(f"[provider] Using cached source: {source_dir}")

    # 3. Compute version
    version = compute_version(ref, source_dir)
    print(f"[provider] Resolved version: {version}")
    return version


def sanitize_ref_for_path(ref: str) -> str:
    """
    Sanitizes a git ref to be safe for directory names.
    Must match the logic in CMakeLists.txt.
    """
    return re.sub(r'[\\/:*?"<>|]', "_", ref)


def is_valid_cached_source(source_dir: Path) -> bool:
    """Return True only if cache contains the expected LLVM source layout."""
    return (source_dir / "llvm" / "CMakeLists.txt").exists()


def compute_version(ref: str, source_dir: Path) -> str:
    """
    Compute PEP 440 version string.

    - Release tags (llvmorg-X.Y.Z) -> X.Y.Z
    - Everything else -> X.Y.Z.dev0+g<sha>
    """
    # Check for release tag pattern
    tag_match = re.match(r"^llvmorg-(\d+\.\d+\.\d+)$", ref)
    if tag_match:
        return tag_match.group(1)

    # Development version: need base version and SHA
    base_ver = get_base_version(source_dir)
    sha = get_commit_sha(ref)

    short_sha = sha[:8] if sha else "unknown"
    return f"{base_ver}.dev0+g{short_sha}"


def get_base_version(source_dir: Path) -> str:
    """Parse Major.Minor.Patch from known LLVM CMake files."""
    candidates = [
        source_dir / "llvm" / "CMakeLists.txt",
        source_dir / "cmake" / "Modules" / "LLVMVersion.cmake",
    ]

    existing_candidates = [p for p in candidates if p.exists()]
    if not existing_candidates:
        raise RuntimeError(
            "Could not determine LLVM base version: none of the expected files exist: "
            + ", ".join(str(p) for p in candidates)
        )

    for cmake_path in candidates:
        if not cmake_path.exists():
            continue

        content = cmake_path.read_text(encoding="utf-8")
        major = parse_cmake_int_var(content, "LLVM_VERSION_MAJOR")
        minor = parse_cmake_int_var(content, "LLVM_VERSION_MINOR")
        patch = parse_cmake_int_var(content, "LLVM_VERSION_PATCH")
        if major is not None and minor is not None and patch is not None:
            return f"{major}.{minor}.{patch}"

    raise RuntimeError(
        "Could not parse LLVM version from expected CMake files: "
        + ", ".join(str(p) for p in existing_candidates)
    )


def parse_cmake_int_var(content: str, var_name: str) -> str | None:
    """Parse an integer value from a CMake set(VAR value ...) statement."""
    pattern = rf"set\(\s*{re.escape(var_name)}\s+\"?(\d+)\"?(?:\s+[^\)]*)?\)"
    match = re.search(pattern, content)
    return match.group(1) if match else None


def get_commit_sha(ref: str) -> str:
    """
    Resolve a git ref to its full commit SHA via the GitHub API.
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

        return data["sha"]

    except (urllib.error.HTTPError, urllib.error.URLError, KeyError) as e:
        raise RuntimeError(
            f"Could not resolve commit metadata for ref {ref!r}: {e}"
        ) from e


def download_and_extract(ref: str, dest_dir: Path) -> None:
    """Download tarball from GitHub and extract to dest_dir."""
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

    extracted = False
    for url in urls:
        try:
            print(f"[provider] Downloading {url}...")
            req = urllib.request.Request(url)
            req.add_header("User-Agent", "halide-llvm-version-provider")

            with urllib.request.urlopen(req, timeout=600) as response:
                content_length = response.headers.get("Content-Length")
                if content_length and content_length.isdigit():
                    size_mb = int(content_length) // 1024 // 1024
                    print(f"[provider] Extracting streamed tarball (~{size_mb} MB)...")
                else:
                    print("[provider] Extracting streamed tarball...")

                with tarfile.open(fileobj=response, mode="r|gz") as tar:
                    tar.extractall(path=temp_dir, filter="data")
            extracted = True
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"[provider] Not found at {url}, trying next...")
                continue
            raise RuntimeError(f"Download failed: {e}") from e
        except (urllib.error.URLError, tarfile.TarError, OSError) as e:
            raise RuntimeError(f"Download or extraction failed for {url}: {e}") from e

    if not extracted:
        shutil.rmtree(temp_dir)
        raise RuntimeError(f"Could not download ref '{ref}' from GitHub.")

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
