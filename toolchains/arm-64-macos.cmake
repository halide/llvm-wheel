# LLVM toolchain for arm-64 macOS (native, Apple Silicon).
#
# Usage:
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/arm-64-macos.cmake \
#     -S llvm-project/llvm -B build

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")

set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 11 CACHE STRING "")
set(LLVM_ENABLE_SUPPORT_XCODE_SIGNPOSTS FORCE_OFF CACHE STRING "")
