# LLVM toolchain for x86-32 Linux (cross-compiled).
#
# Prerequisites (on the host):
#   dpkg --add-architecture i386
#   apt-get install gcc-i686-linux-gnu g++-i686-linux-gnu \
#                   binutils-i686-linux-gnu
#
# Usage:
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/x86-32-linux.cmake \
#     -S llvm-project/llvm -B build

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")

##############################################################################
# Cross-compilation settings
##############################################################################

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR i686)

set(CMAKE_C_COMPILER i686-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER i686-linux-gnu-g++)

set(CMAKE_FIND_ROOT_PATH /usr/lib/i386-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/env)

##############################################################################
# LLVM overrides
##############################################################################

set(LLVM_BUILD_32_BITS ON CACHE BOOL "")
