# initial-cache.cmake -- Canonical LLVM build configuration for Halide
#
# This file is not meant to be used directly. Instead, use one of the
# per-platform toolchain files in this directory:
#
#   cmake -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=halide-llvm/toolchains/x86-64-linux.cmake \
#     -S llvm-project/llvm -B build
#
# See LLVM-Building-Claude.md for a full analysis of the build sites.

##############################################################################
# Core build settings
##############################################################################

set(LLVM_ENABLE_PROJECTS "clang;lld;clang-tools-extra" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")
set(LLVM_TARGETS_TO_BUILD "AArch64;ARM;Hexagon;NVPTX;PowerPC;RISCV;WebAssembly;X86" CACHE STRING "")

##############################################################################
# Features we always want ON
##############################################################################

set(LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
set(LLVM_ENABLE_EH         ON CACHE BOOL "")
set(LLVM_ENABLE_RTTI       ON CACHE BOOL "")

##############################################################################
# Features we always want OFF
#
# These disable optional LLVM features that Halide does not need. Disabling
# them avoids unnecessary host library dependencies and reduces build time.
##############################################################################

set(LLVM_ENABLE_BINDINGS     OFF CACHE BOOL "")
set(LLVM_ENABLE_CURL         OFF CACHE BOOL "")
set(LLVM_ENABLE_DIA_SDK      OFF CACHE BOOL "")
set(LLVM_ENABLE_HTTPLIB      OFF CACHE BOOL "")
set(LLVM_ENABLE_IDE          OFF CACHE BOOL "")
set(LLVM_ENABLE_LIBEDIT      OFF CACHE BOOL "")
set(LLVM_ENABLE_LIBXML2      OFF CACHE BOOL "")
set(LLVM_ENABLE_OCAMLDOC     OFF CACHE BOOL "")
set(LLVM_ENABLE_PLUGINS      OFF CACHE BOOL "")
set(LLVM_ENABLE_TERMINFO     OFF CACHE BOOL "")
set(LLVM_ENABLE_WARNINGS     OFF CACHE BOOL "")
set(LLVM_ENABLE_ZLIB         OFF CACHE BOOL "")
set(LLVM_ENABLE_ZSTD         OFF CACHE BOOL "")

set(LLVM_BUILD_UTILS         OFF CACHE BOOL "")
set(LLVM_INCLUDE_BENCHMARKS  OFF CACHE BOOL "")
set(LLVM_INCLUDE_DOCS        OFF CACHE BOOL "")
set(LLVM_INCLUDE_EXAMPLES    OFF CACHE BOOL "")
set(LLVM_INCLUDE_TESTS       OFF CACHE BOOL "")
set(LLVM_INCLUDE_UTILS       OFF CACHE BOOL "")

##############################################################################
# Clang feature disables
##############################################################################

set(CLANG_ENABLE_ARCMT              OFF CACHE BOOL "")
set(CLANG_ENABLE_CLANGD             OFF CACHE BOOL "")
set(CLANG_ENABLE_STATIC_ANALYZER    OFF CACHE BOOL "")
set(CLANG_INCLUDE_DOCS              OFF CACHE BOOL "")
set(CLANG_INSTALL_SCANBUILD         OFF CACHE BOOL "")
set(CLANG_INSTALL_SCANVIEW          OFF CACHE BOOL "")
set(CLANG_PLUGIN_SUPPORT            OFF CACHE BOOL "")
set(CLANG_TIDY_ENABLE_STATIC_ANALYZER OFF CACHE BOOL "")
set(CLANG_TOOLS_EXTRA_INCLUDE_DOCS  OFF CACHE BOOL "")

##############################################################################
# Clang tool disables
##############################################################################

set(CLANG_TOOL_APINOTES_TEST_BUILD          OFF CACHE BOOL "")
set(CLANG_TOOL_ARCMT_TEST_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_C_ARCMT_TEST_BUILD           OFF CACHE BOOL "")
set(CLANG_TOOL_C_INDEX_TEST_BUILD           OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_CHECK_BUILD            OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_DIFF_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_EXTDEF_MAPPING_BUILD   OFF CACHE BOOL "")
# CLANG_TOOL_CLANG_FORMAT_BUILD -- intentionally left ON
set(CLANG_TOOL_CLANG_FORMAT_VS_BUILD        OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_FUZZER_BUILD           OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_IMPORT_TEST_BUILD      OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD   OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_OFFLOAD_BUNDLER_BUILD  OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_OFFLOAD_PACKAGER_BUILD OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_REFACTOR_BUILD         OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_RENAME_BUILD           OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_REPL_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_SCAN_DEPS_BUILD        OFF CACHE BOOL "")
set(CLANG_TOOL_CLANG_SHLIB_BUILD            OFF CACHE BOOL "")
set(CLANG_TOOL_DIAGTOOL_BUILD               OFF CACHE BOOL "")
set(CLANG_TOOL_DICTIONARY_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_LIBCLANG_BUILD               OFF CACHE BOOL "")
set(CLANG_TOOL_NVPTX_ARCH_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_SCAN_BUILD_BUILD             OFF CACHE BOOL "")
set(CLANG_TOOL_SCAN_BUILD_PY_BUILD          OFF CACHE BOOL "")
set(CLANG_TOOL_SCAN_VIEW_BUILD              OFF CACHE BOOL "")

##############################################################################
# LLVM tool disables
##############################################################################

set(LLVM_TOOL_BUGPOINT_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_BUGPOINT_PASSES_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_DSYMUTIL_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_DXIL_DIS_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_GOLD_BUILD                            OFF CACHE BOOL "")
set(LLVM_TOOL_LLC_BUILD                             OFF CACHE BOOL "")
set(LLVM_TOOL_LLI_BUILD                             OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_AR_BUILD                         OFF CACHE BOOL "")
# LLVM_TOOL_LLVM_AS_BUILD -- intentionally left ON (ClangConfig.cmake needs it)
set(LLVM_TOOL_LLVM_BCANALYZER_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_C_TEST_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CAT_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CFI_VERIFY_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_COV_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CVTRES_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CXXDUMP_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CXXFILT_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_CXXMAP_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DEBUGINFO_ANALYZER_BUILD         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DEBUGINFOD_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DEBUGINFOD_FIND_BUILD            OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DIFF_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DIS_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DIS_FUZZER_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DLANG_DEMANGLE_FUZZER_BUILD      OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DWARFDUMP_BUILD                  OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DWARFUTIL_BUILD                  OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_DWP_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_EXEGESIS_BUILD                   OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_EXTRACT_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_GSYMUTIL_BUILD                   OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_IFS_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_ISEL_FUZZER_BUILD                OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_ITANIUM_DEMANGLE_FUZZER_BUILD    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_JITLINK_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_JITLISTENER_BUILD                OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_LIBTOOL_DARWIN_BUILD             OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_LINK_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_LIPO_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_LTO2_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_LTO_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MC_ASSEMBLE_FUZZER_BUILD         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MC_BUILD                         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MC_DISASSEMBLE_FUZZER_BUILD      OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MCA_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MICROSOFT_DEMANGLE_FUZZER_BUILD  OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_ML_BUILD                         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MODEXTRACT_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_MT_BUILD                         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_NM_BUILD                         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_OBJCOPY_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_OBJDUMP_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_OPT_FUZZER_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_OPT_REPORT_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_PDBUTIL_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_PROFDATA_BUILD                   OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_PROFGEN_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_RC_BUILD                         OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_READOBJ_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_READTAPI_BUILD                   OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_REDUCE_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_REMARKUTIL_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_RTDYLD_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_RUST_DEMANGLE_FUZZER_BUILD       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_SHLIB_BUILD                      OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_SIM_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_SIZE_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_SPECIAL_CASE_LIST_FUZZER_BUILD   OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_SPLIT_BUILD                      OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_STRESS_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_STRINGS_BUILD                    OFF CACHE BOOL "")
# LLVM_TOOL_LLVM_SYMBOLIZER_BUILD -- intentionally left ON (ASAN stack traces)
set(LLVM_TOOL_LLVM_TLI_CHECKER_BUILD                OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_UNDNAME_BUILD                    OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_XRAY_BUILD                       OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_YAML_NUMERIC_PARSER_FUZZER_BUILD OFF CACHE BOOL "")
set(LLVM_TOOL_LLVM_YAML_PARSER_FUZZER_BUILD         OFF CACHE BOOL "")
set(LLVM_TOOL_LTO_BUILD                             OFF CACHE BOOL "")
set(LLVM_TOOL_MLIR_BUILD                            OFF CACHE BOOL "")
set(LLVM_TOOL_OBJ2YAML_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_OPENMP_BUILD                          OFF CACHE BOOL "")
set(LLVM_TOOL_OPT_BUILD                             OFF CACHE BOOL "")
set(LLVM_TOOL_OPT_VIEWER_BUILD                      OFF CACHE BOOL "")
set(LLVM_TOOL_POLLY_BUILD                           OFF CACHE BOOL "")
set(LLVM_TOOL_PSTL_BUILD                            OFF CACHE BOOL "")
set(LLVM_TOOL_REMARKS_SHLIB_BUILD                   OFF CACHE BOOL "")
set(LLVM_TOOL_SANCOV_BUILD                          OFF CACHE BOOL "")
set(LLVM_TOOL_SANSTATS_BUILD                        OFF CACHE BOOL "")
set(LLVM_TOOL_SPIRV_TOOLS_BUILD                     OFF CACHE BOOL "")
set(LLVM_TOOL_VERIFY_USELISTORDER_BUILD             OFF CACHE BOOL "")
set(LLVM_TOOL_VFABI_DEMANGLE_FUZZER_BUILD           OFF CACHE BOOL "")
set(LLVM_TOOL_XCODE_TOOLCHAIN_BUILD                 OFF CACHE BOOL "")
set(LLVM_TOOL_YAML2OBJ_BUILD                        OFF CACHE BOOL "")
