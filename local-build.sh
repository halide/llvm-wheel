#!/usr/bin/env bash
# local-build.sh -- Unified wheel build entrypoint.
#
# Usage:
#   ./local-build.sh <llvm-ref> [platform]
#
# Platforms:
#   local (default): host macOS target local build, host Linux target Docker manylinux
#   x86-64-macos | arm-64-macos: local build
#   x86-64-linux | x86-32-linux | arm-64-linux | arm-32-linux: Docker manylinux build

set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: ./local-build.sh <llvm-ref> [platform]

Platforms:
  local (default)     Host platform (macOS local, Linux via manylinux Docker)
  x86-64-macos        Local macOS x86-64 build
  arm-64-macos        Local macOS ARM64 build
  x86-64-linux        manylinux_2_28_x86_64 (Docker)
  x86-32-linux        manylinux_2_28_i686 (Docker)
  arm-64-linux        manylinux_2_28_aarch64 (Docker)
  arm-32-linux        manylinux_2_31_armv7l (Docker)
USAGE
}

resolve_platform() {
  local requested="$1"
  local host_os host_arch

  if [[ "$requested" != "local" ]]; then
    echo "$requested"
    return
  fi

  host_os="$(uname -s)"
  host_arch="$(uname -m)"

  case "$host_os/$host_arch" in
  Darwin/x86_64) echo "x86-64-macos" ;;
  Darwin/arm64) echo "arm-64-macos" ;;
  Linux/x86_64) echo "x86-64-linux" ;;
  Linux/aarch64) echo "arm-64-linux" ;;
  *)
    echo "error: unsupported host for local platform: $host_os/$host_arch" >&2
    exit 1
    ;;
  esac
}

run_local_macos_build() {
  local platform="$1"
  local toolchain_path dist_dir host_os host_arch

  case "$platform" in
  x86-64-macos|arm-64-macos) ;;
  *)
    echo "error: unsupported local platform: $platform" >&2
    exit 1
    ;;
  esac

  host_os="$(uname -s)"
  host_arch="$(uname -m)"
  if [[ "$host_os" != "Darwin" ]]; then
    echo "error: local macOS build requested, but host is $host_os/$host_arch" >&2
    exit 1
  fi

  toolchain_path="toolchains/$platform.cmake"

  export MACOSX_DEPLOYMENT_TARGET=11

  dist_dir="dist/$platform"
  mkdir -p "$dist_dir"

  if [[ ! -d .venv ]]; then
    echo "Creating virtual environment..."
    uv venv .venv
  fi

  echo "Installing build dependencies..."
  uv pip install --quiet "scikit-build-core>=0.10"

  local config_settings=(
    "--config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=$toolchain_path"
  )

  if command -v ccache &>/dev/null; then
    config_settings+=(
      "--config-settings=cmake.define.CMAKE_C_COMPILER_LAUNCHER=ccache"
      "--config-settings=cmake.define.CMAKE_CXX_COMPILER_LAUNCHER=ccache"
    )
  fi

  echo "Building halide-llvm (local macOS)"
  echo "  HALIDE_LLVM_REF: $HALIDE_LLVM_REF"
  echo "  Platform: $platform"
  echo "  Toolchain: $toolchain_path"
  echo "  Output: $dist_dir/"

  uv build --wheel -v --no-build-isolation --out-dir "$dist_dir" "${config_settings[@]}"
}

run_linux_docker_build() {
  local platform="$1"
  local image dist_dir
  local toolchain="toolchains/$platform.cmake"

  case "$platform" in
  x86-64-linux)
    image="quay.io/pypa/manylinux_2_28_x86_64"
    ;;
  x86-32-linux)
    image="quay.io/pypa/manylinux_2_28_i686"
    ;;
  arm-64-linux)
    image="quay.io/pypa/manylinux_2_28_aarch64"
    ;;
  arm-32-linux)
    image="quay.io/pypa/manylinux_2_31_armv7l"
    ;;
  *)
    echo "error: unsupported Linux Docker platform: $platform" >&2
    exit 1
    ;;
  esac

  dist_dir="dist/$platform"
  mkdir -p "$dist_dir"

  echo "Building halide-llvm (manylinux Docker)"
  echo "  HALIDE_LLVM_REF: $HALIDE_LLVM_REF"
  echo "  Platform: $platform"
  echo "  Image: $image"
  echo "  Output: $dist_dir/"

  docker run --rm \
    -v "$(pwd):/project" \
    -w /project \
    -e "HALIDE_LLVM_REF=$HALIDE_LLVM_REF" \
    "$image" \
    bash -c "
      set -euo pipefail
      export PATH=/opt/python/cp312-cp312/bin:\$PATH

      pip wheel . -w $dist_dir/ -v \
        --config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=$toolchain

      pip install auditwheel
      auditwheel repair -w $dist_dir/ $dist_dir/*.whl
      rm -f $dist_dir/*-linux_*.whl

      echo
      echo 'Built wheels:'
      ls -lh $dist_dir/*.whl
    "
}

REF="${1:-}"
REQUESTED_PLATFORM="${2:-local}"

if [[ -z "$REF" || "$#" -gt 2 ]]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export HALIDE_LLVM_REF="$REF"
PLATFORM="$(resolve_platform "$REQUESTED_PLATFORM")"

case "$PLATFORM" in
x86-64-macos|arm-64-macos)
  run_local_macos_build "$PLATFORM"
  ;;
x86-64-linux|x86-32-linux|arm-64-linux|arm-32-linux)
  run_linux_docker_build "$PLATFORM"
  ;;
*)
  echo "error: unknown platform: $PLATFORM" >&2
  usage
  exit 1
  ;;
esac
