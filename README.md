# halide-llvm

Pre-built LLVM wheels for [Halide](https://github.com/halide/Halide), hosted on
[pypi.halide-lang.org](https://pypi.halide-lang.org/). Builds against any
arbitrary LLVM git reference (tag, branch, or commit SHA) and produces
manylinux, macOS, and Windows wheels.

## Installation

```bash
pip install halide-llvm==21.1.8 \
  --extra-index-url https://pypi.halide-lang.org/simple/
```

### Available platforms

| Platform       | Wheel tag                |
|----------------|--------------------------|
| Linux x86-64   | `manylinux_2_28_x86_64`  |
| Linux x86-32   | `manylinux_2_28_i686`    |
| Linux AArch64  | `manylinux_2_28_aarch64` |
| Linux ARMv7    | `manylinux_2_31_armv7l`  |
| macOS x86-64   | `macosx_11_0_x86_64`     |
| macOS ARM64    | `macosx_11_0_arm64`      |
| Windows x86-64 | `win_amd64`              |
| Windows x86-32 | `win32`                  |

### Usage with CMake

After installing, use the CLI to get the paths CMake needs:

```bash
# LLVM installation prefix (contains bin/, lib/, include/)
halide-llvm --prefix

# Directly usable with CMake
cmake -DHalide_LLVM_ROOT=$(halide-llvm --prefix) ...
```

All CLI options:

```
halide-llvm --prefix       # Installation root
halide-llvm --bindir       # bin/ directory (clang, lld, etc.)
halide-llvm --includedir   # include/ directory
halide-llvm --libdir       # lib/ directory
halide-llvm --cmakedir     # CMake modules (lib/cmake/llvm/)
```

### Usage from Python

```python
from halide_llvm import get_root_dir, get_cmake_dir, get_bin_dir

llvm_prefix = get_root_dir()
cmake_dir = get_cmake_dir()
clang = get_bin_dir() / "clang"
```

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

1. **User sets `HALIDE_LLVM_REF`** (e.g., `llvmorg-21.1.8` or `main`)
2. **Version provider runs** (`_version_provider.py`):

- Downloads the LLVM tarball from GitHub into `src_cache/<ref>/`
- Computes a PEP 440 version string

3. **CMake configures** (`CMakeLists.txt`):

- Reads `HALIDE_LLVM_REF` from the environment
- Finds the cached source at `src_cache/<ref>/`
- Applies settings from `toolchains/initial-cache.cmake`
- Builds LLVM via `add_subdirectory()`

### Version Strings

| Ref                  | Version                 |
|----------------------|-------------------------|
| `llvmorg-21.1.8`     | `21.1.8`                |
| `llvmorg-22.1.0-rc2` | `22.1.0rc2`             |
| `main`               | `22.0.0.dev0+gabcd1234` |
| `<commit-sha>`       | `22.0.0.dev0+gabcd1234` |

Release tags produce clean versions. RC tags produce PEP 440 pre-release
versions. Everything else produces dev versions with a short SHA for
traceability.

## Build Instructions

**Prerequisites:**

- C++ compiler (Clang, GCC, or MSVC)
- CMake 3.21+
- Ninja
- Python 3.12+

### Release Build

```bash
export HALIDE_LLVM_REF="llvmorg-21.1.8"
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
export HALIDE_LLVM_REF="llvmorg-21.1.8"
pip wheel . --config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=toolchains/x86-64-linux.cmake
```

## Toolchains

Pre-configured toolchain files are provided in `toolchains/`:

| File                   | Platform                                           |
|------------------------|----------------------------------------------------|
| `x86-64-linux.cmake`   | Linux x86-64 (native)                              |
| `x86-32-linux.cmake`   | Linux x86-32 (cross-compile)                       |
| `arm-32-linux.cmake`   | Linux arm-32 (cross-compile)                       |
| `arm-64-linux.cmake`   | Linux arm-64 (native)                              |
| `x86-64-macos.cmake`   | macOS x86-64 (native)                              |
| `arm-64-macos.cmake`   | macOS arm-64 (native, Apple Silicon)               |
| `x86-64-windows.cmake` | Windows x86-64 (native, requires vcvarsall)        |
| `x86-32-windows.cmake` | Windows x86-32 (cross-compile, requires vcvarsall) |

All toolchains include `initial-cache.cmake` which configures:

- Projects: clang, lld, clang-tools-extra
- Runtimes: compiler-rt, libcxx, libcxxabi, libunwind
- Targets: AArch64, ARM, Hexagon, NVPTX, PowerPC, RISCV, WebAssembly, X86
- Assertions, RTTI, and exception handling enabled
- Unnecessary tools and features disabled for faster builds

## Environment Variables

| Variable          | Required | Description                            |
|-------------------|----------|----------------------------------------|
| `HALIDE_LLVM_REF` | Yes      | Git ref to build (tag, branch, or SHA) |
| `GITHUB_TOKEN`    | No       | Avoids GitHub API rate limiting in CI  |

## CI Workflow

The `build-wheels.yml` workflow builds and uploads wheels for all platforms:

```bash
gh workflow run build-wheels.yml -f llvm_ref=llvmorg-21.1.8
```

It will skip the build if wheels for that ref already exist on
pypi.halide-lang.org. Wheels are uploaded automatically after all platform
builds succeed.

## Caching

Downloaded sources are cached in `src_cache/`. To force a re-download, delete
the corresponding directory:

```bash
rm -rf src_cache/llvmorg-21.1.8
```

## Known Issues

- **scikit-build-core x86 cross-compile tag bug:** On Windows, cross-compiling
  for x86 from an x64 host produces a wheel incorrectly tagged `win_amd64`. The
  CI workflow works around this by retagging the wheel after building. See
  `get_archs()` in scikit-build-core's `builder/builder.py`.
