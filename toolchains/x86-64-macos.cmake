# LLVM toolchain for x86-64 macOS (native).
#
# Usage:
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/x86-64-macos.cmake \
#     -S llvm-project/llvm -B build

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")

set(CMAKE_OSX_ARCHITECTURES x86_64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 11 CACHE STRING "")
set(LLVM_ENABLE_SUPPORT_XCODE_SIGNPOSTS FORCE_OFF CACHE STRING "")
