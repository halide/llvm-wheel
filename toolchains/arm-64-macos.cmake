# LLVM toolchain for arm-64 macOS (native, Apple Silicon).

set(CMAKE_OSX_ARCHITECTURES arm64)
set(LLVM_ENABLE_SUPPORT_XCODE_SIGNPOSTS FORCE_OFF CACHE STRING "")

include("${CMAKE_CURRENT_LIST_DIR}/initial-cache.cmake")
