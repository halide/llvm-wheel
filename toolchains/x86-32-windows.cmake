# LLVM toolchain for x86-32 Windows (cross-compiled from x64 host).
#
# This toolchain file does not configure the compiler. MSVC must be set up
# in the environment before invoking CMake (e.g., by running vcvarsall.bat,
# using a VS Developer Command Prompt, or via ilammy/msvc-dev-cmd in GitHub
# Actions). Use the x64_x86 target to cross-compile for 32-bit from a 64-bit
# host.
#
# Usage:
#   vcvarsall.bat x64_x86
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/x86-32-windows.cmake \
#     -S llvm-project/llvm -B build

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")

set(LLVM_DEFAULT_TARGET_TRIPLE "i686-pc-windows-msvc" CACHE STRING "")
