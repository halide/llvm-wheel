# halide-llvm

Halide's build of LLVM libraries and tools for development.

## Overview

This package provides a Python wheel containing LLVM libraries and tools
compiled specifically for Halide development. It includes essential LLVM
components with a focused configuration optimized for Halide's needs.

## What's Included

- **LLVM Core Libraries** with assertions and RTTI enabled
- **Clang** compiler and tools
- **LLD** linker
- **Clang Tools Extra** for additional development utilities

### Target Architectures

The build supports the following target architectures:

- X86
- ARM
- NVPTX (CUDA)
- AArch64
- Hexagon
- PowerPC
- WebAssembly
- RISC-V

## Installation

Due to the large size of LLVM binaries, this package is hosted on a custom PyPI
index:

```bash
pip install halide-llvm --extra-index-url https://pypi.halide-lang.org/simple/
```

## Building from Source

This package uses `scikit-build-core` for building. The version is automatically
determined from the LLVM source being built.

### Requirements

- Python 3.12 or later
- CMake 4.0 or later
- C++ compiler

### Build

```bash
pip install -e .
```

### Configuration

The LLVM build configuration can be customized by modifying the
`halide-llvm_GIT_TAG` variable to specify a different LLVM version:

- `"main"` - Latest development version
- `"llvmorg-X.Y.Z"` - Specific release version (e.g., "llvmorg-18.1.0")

## Development

This build is specifically configured for Halide development with:

- Assertions enabled for debugging
- Exception handling support
- RTTI (Run-Time Type Information) enabled
- Zlib compression support
- Most optional tools and utilities disabled to reduce build time and size

## License

This package contains LLVM software, which is licensed under the Apache License
v2.0 with LLVM Exceptions. See the LLVM project for full license details.
