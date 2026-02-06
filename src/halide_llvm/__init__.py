"""
halide-llvm: LLVM distribution for Halide.

This package provides a pre-built LLVM installation. Use the helper functions
to locate the LLVM installation directory for use with CMake.
"""

from importlib.metadata import version
from importlib.resources import files
from pathlib import Path

__version__ = version("halide-llvm")


def get_root_dir() -> Path:
    """
    Return the path to the LLVM installation directory.

    This is the root of the installed LLVM tree, containing bin/, lib/,
    include/, etc.
    """
    # LLVM is installed into halide_llvm/data/ via wheel.install-dir
    package_dir = Path(files("halide_llvm"))  # type: ignore[arg-type]
    data_dir = package_dir / "data"
    if data_dir.exists():
        return data_dir

    raise RuntimeError(
        f"Could not locate halide-llvm data directory. Expected at {data_dir}"
    )


def get_cmake_dir() -> Path:
    """Return the path to LLVM's CMake modules directory."""
    return get_root_dir() / "lib" / "cmake" / "llvm"


def get_bin_dir() -> Path:
    """Return the path to LLVM's bin directory (contains clang, lld, etc.)."""
    return get_root_dir() / "bin"


def get_include_dir() -> Path:
    """Return the path to LLVM's include directory."""
    return get_root_dir() / "include"


def get_lib_dir() -> Path:
    """Return the path to LLVM's lib directory."""
    return get_root_dir() / "lib"


def main():
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        prog="halide-llvm",
        description="Print paths to the installed LLVM distribution.",
    )
    parser.add_argument("--version", action="version", version=__version__)

    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--prefix", action="store_true", help="Print the installation prefix."
    )
    group.add_argument(
        "--bindir", action="store_true", help="Directory containing LLVM executables."
    )
    group.add_argument(
        "--includedir", action="store_true", help="Directory containing LLVM headers."
    )
    group.add_argument(
        "--libdir", action="store_true", help="Directory containing LLVM libraries."
    )
    group.add_argument(
        "--cmakedir",
        action="store_true",
        help="Directory containing LLVM CMake modules.",
    )

    args = parser.parse_args()

    if args.prefix:
        print(get_root_dir())
    elif args.bindir:
        print(get_bin_dir())
    elif args.includedir:
        print(get_include_dir())
    elif args.libdir:
        print(get_lib_dir())
    elif args.cmakedir:
        print(get_cmake_dir())
    else:
        # Default: print prefix
        print(get_root_dir())


if __name__ == "__main__":
    main()
