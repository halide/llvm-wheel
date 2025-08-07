cmake_minimum_required(VERSION 4.0)
project(halide-llvm LANGUAGES NONE)

set(halide-llvm_GIT_TAG "main"
    CACHE STRING "LLVM reference to package")

if (halide-llvm_GIT_TAG STREQUAL "main")
    set(url "heads/main.tar.gz")
elseif (halide-llvm_GIT_TAG MATCHES "^llvmorg-[0-9]+\\.[0-9]+\\.[0-9]+$")
    set(url "tags/${halide-llvm_GIT_TAG}.tar.gz")
else ()
    message(FATAL_ERROR "halide-llvm_GIT_TAG should be set to a release tag or `main`")
endif ()

include(FetchContent)
FetchContent_Declare(
    LLVM
    URL "https://github.com/llvm/llvm-project/archive/refs/${url}"
    SOURCE_SUBDIR llvm
)
FetchContent_MakeAvailable(LLVM)
