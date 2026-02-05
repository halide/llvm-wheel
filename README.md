# halide-llvm

A Python-packaged LLVM distribution for Halide. Builds wheels against any
arbitrary git reference (tag, branch, or commit SHA) without modifying source.

## Why This Architecture?

LLVM is a massive monorepo (gigabytes of history). Standard packaging approaches
fail here:

- **Git submodules are too heavy:** Cloning full history for every CI run is
  agonizingly slow.
- **Hardcoded versions are too rigid:** We often need to build against specific
  commits to test upstream fixes or experimental features.
- **PEP 517 build isolation:** Python build frontends isolate the build
  environment, making it difficult to inject source code from the outside.

**The Solution:** We use `scikit-build-core` with a custom **Dynamic Version
Provider** that reads `HALIDE_LLVM_REF` from the environment. This single
variable controls both the version string and the source code to fetch.

## How It Works

1. **User sets `HALIDE_LLVM_REF`** (e.g., `llvmorg-21.1.6` or `main`)
2. **Version provider runs** (`_version_provider.py`):
   - Downloads the LLVM tarball from GitHub into `src_cache/<ref>/`
   - Computes a PEP 440 version string
3. **CMake configures** (`CMakeLists.txt`):
   - Reads `HALIDE_LLVM_REF` from the environment
   - Finds the cached source at `src_cache/<ref>/`
   - Applies settings from `toolchains/initial-cache.cmake`
   - Builds LLVM via `add_subdirectory()`

### Version Strings

| Ref | Version |
|-----|---------|
| `llvmorg-21.1.6` | `21.1.6` |
| `main` | `22.0.0.dev202502051630+gabcd1234` |
| `<commit-sha>` | `22.0.0.dev202502051630+gabcd1234` |

Release tags produce clean versions. Everything else produces dev versions with
a timestamp (for monotonic ordering) and short SHA (for traceability).

## Build Instructions

**Prerequisites:**
- C++ compiler (Clang, GCC, or MSVC)
- CMake 3.21+
- Ninja
- Python 3.10+

### Release Build

```bash
export HALIDE_LLVM_REF="llvmorg-21.1.6"
pip wheel . --no-build-isolation
```

### Development Build (main branch)

```bash
export HALIDE_LLVM_REF="main"
pip wheel . --no-build-isolation
```

### Incremental Rebuilds

LLVM caches the Python interpreter path. When using build isolation (the
default), the ephemeral venv path changes between runs, breaking incremental
builds. For local development, always use `--no-build-isolation`:

```bash
# pip
pip wheel . --no-build-isolation

# uv
UV_NO_BUILD_ISOLATION=1 uv build --wheel
```

For CI, where you want fresh builds anyway, build isolation is fine.

### With a Specific Toolchain

```bash
export HALIDE_LLVM_REF="llvmorg-21.1.6"
pip wheel . --config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=toolchains/x86-64-linux.cmake
```

## Toolchains

Pre-configured toolchain files are provided in `toolchains/`:

| File | Platform |
|------|----------|
| `x86-64-linux.cmake` | Linux x86-64 (native) |
| `x86-32-linux.cmake` | Linux x86-32 (cross-compile) |
| `arm-32-linux.cmake` | Linux arm-32 (cross-compile) |
| `arm-64-linux.cmake` | Linux arm-64 (native) |
| `x86-64-macos.cmake` | macOS x86-64 (native) |
| `arm-64-macos.cmake` | macOS arm-64 (native, Apple Silicon) |
| `x86-64-windows.cmake` | Windows x86-64 (native, requires vcvarsall) |
| `x86-32-windows.cmake` | Windows x86-32 (cross-compile, requires vcvarsall) |

All toolchains include `initial-cache.cmake` which configures:
- Projects: clang, lld, clang-tools-extra
- Runtimes: compiler-rt, libcxx, libcxxabi, libunwind
- Targets: AArch64, ARM, Hexagon, NVPTX, PowerPC, RISCV, WebAssembly, X86
- Assertions, RTTI, and exception handling enabled
- Unnecessary tools and features disabled for faster builds

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HALIDE_LLVM_REF` | Yes | Git ref to build (tag, branch, or SHA) |
| `GITHUB_TOKEN` | No | Avoids GitHub API rate limiting in CI |

## Caching

Downloaded sources are cached in `src_cache/`. To force a re-download, delete
the corresponding directory:

```bash
rm -rf src_cache/llvmorg-21.1.6
```
