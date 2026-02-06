#!/usr/bin/env bash
# local-build.sh -- Build halide-llvm wheel for local development
#
# Usage:
#   export HALIDE_LLVM_REF=llvmorg-21.1.8
#   ./local-build.sh
#
# This script:
#   - Validates HALIDE_LLVM_REF is set
#   - Auto-detects the host platform and selects the appropriate toolchain
#   - Enables ccache if available
#   - Builds with --no-build-isolation for incremental rebuilds

set -euo pipefail

# Validate HALIDE_LLVM_REF
if [[ -z "${HALIDE_LLVM_REF:-}" ]]; then
  echo "error: HALIDE_LLVM_REF is not set" >&2
  echo "" >&2
  echo "Usage:" >&2
  echo "  export HALIDE_LLVM_REF=llvmorg-21.1.8  # or 'main', or a commit SHA" >&2
  echo "  ./local-build.sh" >&2
  exit 1
fi

# Detect host platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
Linux)
  case "$ARCH" in
  x86_64) TOOLCHAIN="x86-64-linux.cmake" ;;
  aarch64) TOOLCHAIN="arm-64-linux.cmake" ;;
  *)
    echo "error: unsupported Linux architecture: $ARCH" >&2
    exit 1
    ;;
  esac
  ;;
Darwin)
  export MACOSX_DEPLOYMENT_TARGET=11
  case "$ARCH" in
  x86_64) TOOLCHAIN="x86-64-macos.cmake" ;;
  arm64) TOOLCHAIN="arm-64-macos.cmake" ;;
  *)
    echo "error: unsupported macOS architecture: $ARCH" >&2
    exit 1
    ;;
  esac
  ;;
*)
  echo "error: unsupported OS: $OS" >&2
  echo "hint: on Windows, use pip directly with the appropriate toolchain" >&2
  exit 1
  ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_PATH="$SCRIPT_DIR/toolchains/$TOOLCHAIN"

cd "$SCRIPT_DIR"

# Bootstrap build environment
if [[ ! -d "$SCRIPT_DIR/.venv" ]]; then
  echo "Creating virtual environment..."
  uv venv "$SCRIPT_DIR/.venv"
fi

echo "Installing build dependencies..."
uv pip install --quiet "scikit-build-core>=0.10"

echo ""
echo "Building halide-llvm"
echo "  HALIDE_LLVM_REF: $HALIDE_LLVM_REF"
echo "  Toolchain: $TOOLCHAIN"

# Build config settings
CONFIG_SETTINGS=(
  "--config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_PATH"
)

# Enable ccache if available
if command -v ccache &>/dev/null; then
  echo "  ccache: enabled"
  CONFIG_SETTINGS+=(
    "--config-settings=cmake.define.CMAKE_C_COMPILER_LAUNCHER=ccache"
    "--config-settings=cmake.define.CMAKE_CXX_COMPILER_LAUNCHER=ccache"
  )
else
  echo "  ccache: not found (install for faster rebuilds)"
fi

echo ""

# Run the build
uv build --wheel --no-build-isolation "${CONFIG_SETTINGS[@]}"

# Repair wheel (macOS only)
# Disabled: delocate's -e flag does not apply to the deployment target
# version check, so excluded iossim/ios dylibs still cause a false
# failure. Our CMAKE_INSTALL_RPATH settings handle runtime resolution.
# See: https://github.com/matthew-brett/delocate/issues/273
#if [[ "$OS" == "Darwin" ]]; then
#    echo ""
#    echo "Running delocate-wheel..."
#    uvx --from delocate delocate-wheel -e iossim dist/*.whl
#fi
