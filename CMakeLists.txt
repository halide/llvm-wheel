cmake_minimum_required(VERSION 3.21)
project(halide-llvm LANGUAGES C CXX)

# =============================================================================
# 1. Retrieve the Ref (Source of Truth)
# =============================================================================
set(HALIDE_LLVM_REF "$ENV{HALIDE_LLVM_REF}")
if (NOT HALIDE_LLVM_REF)
    message(FATAL_ERROR
        "HALIDE_LLVM_REF environment variable is required.\n"
        "Examples: 'llvmorg-21.1.8', 'main', or a commit SHA"
    )
endif ()

# =============================================================================
# 2. Calculate the Source Path
# =============================================================================
# Must match Python's sanitize_ref_for_path logic: replace invalid chars with _
string(REGEX REPLACE "[\\\\/:*?\"<>|]" "_" SAFE_REF "${HALIDE_LLVM_REF}")
set(LLVM_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src_cache/${SAFE_REF}")

# Validate that the source was downloaded by the version provider
if (NOT EXISTS "${LLVM_SOURCE_DIR}/llvm/CMakeLists.txt")
    message(FATAL_ERROR
        "LLVM source for ref '${HALIDE_LLVM_REF}' not found at:\n"
        "  ${LLVM_SOURCE_DIR}\n"
        "The Python version provider should have downloaded it.\n"
        "Try running: HALIDE_LLVM_REF=${HALIDE_LLVM_REF} pip wheel ."
    )
endif ()

message(STATUS "halide-llvm: Configuring LLVM from ${LLVM_SOURCE_DIR}")

# =============================================================================
# 3. Apply LLVM Configuration from Toolchain
# =============================================================================
# The toolchain file (via CMAKE_TOOLCHAIN_FILE) should have already included
# toolchains/initial-cache.cmake which sets all the LLVM_* variables.
#
# If no toolchain was specified, include the initial cache directly.
if (NOT CMAKE_TOOLCHAIN_FILE)
    message(STATUS "halide-llvm: No toolchain file specified, using initial-cache.cmake")
    include("${CMAKE_CURRENT_SOURCE_DIR}/toolchains/initial-cache.cmake")
endif ()

# =============================================================================
# 4. Build LLVM
# =============================================================================
add_subdirectory("${LLVM_SOURCE_DIR}/llvm" llvm-build)

# =============================================================================
# 5. Post-install cleanup: convert clang symlinks to wrappers
# =============================================================================
# LLVM creates symlinks like clang++ -> clang, but wheels are ZIP files that
# don't support symlinks. Each "symlink" becomes a full ~128MB copy.
# We replace them with small bash wrappers to save space while keeping functionality.
install(CODE "set(CONVERT_SYMLINK_SCRIPT \"${CMAKE_CURRENT_SOURCE_DIR}/convert-symlink.sh\")")
install(CODE [[
    file(GLOB binaries "${CMAKE_INSTALL_PREFIX}/bin/*")
    foreach (binary IN LISTS binaries)
        if (IS_SYMLINK "${binary}")
            message(STATUS "Converting symlink: ${binary}")
            execute_process(
                COMMAND bash "${CONVERT_SYMLINK_SCRIPT}" "${binary}"
                RESULT_VARIABLE res
                ERROR_VARIABLE err
            )
            if (NOT res EQUAL 0)
                message(FATAL_ERROR "Failed to convert symlink: ${err}")
            endif ()
        endif ()
    endforeach ()
]])