# LLVM toolchain for arm-32 Linux (native).
#
# Intended for use inside a native armv7l environment (e.g.,
# manylinux_2_31_armv7l container in CI). For cross-compiling from an
# aarch64 host, uncomment the cross-compilation settings below.
#
# Cross-compilation prerequisites (on the aarch64 host):
#   apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
#                   binutils-arm-linux-gnueabihf
#
# On an aarch64 host, you can also run the results if you:
#   dpkg --add-architecture armhf
#   apt-get install libc6:armhf libstdc++6:armhf
#
# Usage:
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/arm-32-linux.cmake \
#     -S llvm-project/llvm -B build

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")

##############################################################################
# Cross-compilation settings (uncomment for aarch64 -> armv7l cross builds)
##############################################################################

# set(CMAKE_SYSTEM_NAME Linux)
# set(CMAKE_SYSTEM_PROCESSOR arm)

# set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
# set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)

# set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# add_custom_command() will make bad decisions about running the command
# when crosscompiling (it won't expand the target into a full path).
# Setting CMAKE_CROSSCOMPILING_EMULATOR to /usr/bin/env tricks it into
# doing the right thing (ie, running it directly). Note that if you want
# to build/run on x86-64 systems, you could set this to some qemu command
# (though the results will likely be very slow).
# set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/env)

# set(LLVM_TARGET_ARCH            ARM CACHE STRING "")
# set(LLVM_DEFAULT_TARGET_TRIPLE  "arm-linux-gnueabihf" CACHE STRING "")

##############################################################################
# LLVM overrides
##############################################################################

# As of 12/11/2025, LLVM doesn't build on arm-32 with RTTI.
set(LLVM_ENABLE_RTTI OFF CACHE BOOL "")
