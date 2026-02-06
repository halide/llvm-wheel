# LLVM toolchain for x86-32 Linux (native).
#
# Intended for use inside a native i686 environment (e.g., manylinux_2_28_i686
# container in CI). For cross-compiling from an x86-64 host, uncomment the
# cross-compilation settings below.
#
# Cross-compilation prerequisites (on the x86-64 host):
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
# Cross-compilation settings (uncomment for x86-64 -> i686 cross builds)
##############################################################################

# set(CMAKE_SYSTEM_NAME Linux)
# set(CMAKE_SYSTEM_PROCESSOR i686)

# set(CMAKE_C_COMPILER i686-linux-gnu-gcc)
# set(CMAKE_CXX_COMPILER i686-linux-gnu-g++)

# set(CMAKE_FIND_ROOT_PATH /usr/lib/i386-linux-gnu)
# set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/env)

# set(LLVM_DEFAULT_TARGET_TRIPLE "i686-linux-gnu" CACHE STRING "")
