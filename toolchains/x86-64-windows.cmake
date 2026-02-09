# LLVM toolchain for x86-64 Windows (native).
#
# This toolchain file does not configure the compiler. MSVC must be set up
# in the environment before invoking CMake (e.g., by running vcvarsall.bat,
# using a VS Developer Command Prompt, or via ilammy/msvc-dev-cmd in GitHub
# Actions).
#
# Usage:
#   vcvarsall.bat x64
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/x86-64-windows.cmake \
#     -S llvm-project/llvm -B build

# Only compiler-rt is relevant on Windows. libc++, libc++abi, and libunwind
# are tied to the Itanium C++ ABI and do not build with MSVC.
set(LLVM_ENABLE_RUNTIMES "compiler-rt" CACHE STRING "")

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")
