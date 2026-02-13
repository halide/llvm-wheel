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
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Mapping

# --- Configuration ---
CACHE_ROOT = Path(__file__).parent / "src_cache"

# Epoch tag for dev version numbering. The dev version number is the commit
# distance from this point, which is guaranteed monotonically increasing along
# LLVM's linear main branch. Chosen to predate our entire support matrix.
_EPOCH_COMMIT = "llvmorg-19-init"


def dynamic_metadata(
    field: str,
    _settings: Mapping[str, Any] | None = None,
) -> str:
    """scikit-build-core dynamic metadata hook."""
    if field != "version":
        msg = f"Only 'version' is supported, not {field!r}"
        raise RuntimeError(msg)

    ref = os.environ.get("HALIDE_LLVM_REF")
    if not ref:
        msg = (
            "Environment variable 'HALIDE_LLVM_REF' is required.\n"
            "Examples: 'llvmorg-21.1.8', 'main', or a commit SHA"
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


def version_from_tag(ref: str) -> str | None:
    """
    If ref is a release or RC tag, return its PEP 440 version string.

    Returns None for non-tag refs (branches, SHAs, init tags, etc.).
    """
    tag_match = re.match(r"^llvmorg-(\d+\.\d+\.\d+)(?:-(rc\d+))?$", ref)
    if tag_match:
        version = tag_match.group(1)
        rc = tag_match.group(2)
        return f"{version}{rc or ''}"
    return None


def compute_version(ref: str, source_dir: Path) -> str:
    """
    Compute PEP 440 version string.

    - Release tags (llvmorg-X.Y.Z) -> X.Y.Z
    - RC tags (llvmorg-X.Y.Z-rcN) -> X.Y.ZrcN
    - Everything else -> X.Y.Z.devN+g<sha> (N = commits since epoch)
    """
    if version := version_from_tag(ref):
        return version

    # Development version: need base version, SHA, and commit distance
    version = get_base_version(source_dir)
    sha, distance = get_commit_info(ref)

    short_sha = sha[:8] if sha else "unknown"
    return f"{version}.dev{distance}+g{short_sha}"


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

    for cmake_path in existing_candidates:
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


def _github_api(endpoint: str) -> Any:
    """Fetch JSON from the GitHub API (llvm/llvm-project)."""
    url = f"https://api.github.com/repos/llvm/llvm-project/{endpoint}"
    req = urllib.request.Request(url)
    req.add_header("User-Agent", "halide-llvm-version-provider")
    req.add_header("Accept", "application/vnd.github+json")

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"token {token}")

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except (urllib.error.HTTPError, urllib.error.URLError) as e:
        raise RuntimeError(f"GitHub API request failed ({endpoint}): {e}") from e


def get_commit_info(ref: str) -> tuple[str, int]:
    """
    Resolve a git ref to (full_sha, commit_distance_from_epoch).

    Uses the GitHub compare API to count commits between the epoch and the
    given ref. This count is guaranteed monotonically increasing along any
    linear history path.
    """
    print(f"[provider] Fetching commit info for '{ref}' (compare to epoch)...")
    # Compare in reverse order so the ref (base_commit) gets resolved to an SHA.
    # This reverses the intuitive roles of ahead_by and behind_by.
    data = _github_api(f"compare/{ref}...{_EPOCH_COMMIT}")

    if (ahead_by := data["ahead_by"]) != 0:
        raise RuntimeError(
            f"Ref {ref!r} is {ahead_by} commits behind the epoch commit "
            f"({_EPOCH_COMMIT}). This ref predates the support matrix."
        )

    return data["base_commit"]["sha"], data["behind_by"]


def download_and_extract(ref: str, dest_dir: Path) -> None:
    """Download tarball from GitHub and extract to dest_dir."""
    # GitHub tarball URLs to try (tag URL first, then generic)
    urls = [
        f"https://github.com/llvm/llvm-project/archive/refs/tags/{ref}.tar.gz",
        f"https://github.com/llvm/llvm-project/archive/{ref}.tar.gz",
    ]

    dest_dir.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=dest_dir.parent) as temp_dir:
        temp_path = Path(temp_dir)

        tarball = temp_path / "download.tar.gz"

        for url in urls:
            try:
                print(f"[provider] Downloading {url}...")
                req = urllib.request.Request(url)
                req.add_header("User-Agent", "halide-llvm-version-provider")

                with urllib.request.urlopen(req, timeout=600) as response:
                    with open(tarball, "wb") as f:
                        shutil.copyfileobj(response, f)

                break
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    print(f"[provider] Not found at {url}, trying next...")
                    continue
                raise RuntimeError(f"Download failed: {e}") from e
            except (urllib.error.URLError, OSError) as e:
                raise RuntimeError(f"Download failed for {url}: {e}") from e
        else:  # if the loop completes without a break, all URLs failed
            raise RuntimeError(f"Could not download ref '{ref}' from GitHub.")

        print("[provider] Extracting tarball...")
        with tarfile.open(tarball, mode="r:gz") as tar:
            tar.extractall(path=temp_path, filter="data")

        # GitHub tarballs have a single root directory like 'llvm-project-<ref>/'
        extracted_roots = [p for p in temp_path.iterdir() if p.is_dir()]
        if not extracted_roots:
            raise RuntimeError("Tarball appeared empty or invalid.")

        # Move inner content to final destination
        if dest_dir.exists():
            shutil.rmtree(dest_dir)
        shutil.move(str(extracted_roots[0]), str(dest_dir))

    print(f"[provider] Extracted to {dest_dir}")
