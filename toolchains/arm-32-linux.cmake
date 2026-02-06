# LLVM toolchain for arm-32 Linux (native, armv7l).

# As of 12/11/2025, LLVM doesn't build on arm-32 with RTTI.
set(LLVM_ENABLE_EH OFF CACHE BOOL "")
set(LLVM_ENABLE_RTTI OFF CACHE BOOL "")

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")