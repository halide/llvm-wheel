#!/usr/bin/env bash
set -euo pipefail

REF="${1:?Usage: $0 <llvm-ref> [platform]}"
PLATFORM="${2:-x86-64-linux}"

case "$PLATFORM" in
x86-64-linux)
  IMAGE=quay.io/pypa/manylinux_2_28_x86_64
  TOOLCHAIN=x86-64-linux.cmake
  ;;
x86-32-linux)
  IMAGE=quay.io/pypa/manylinux_2_28_i686
  TOOLCHAIN=x86-32-linux.cmake
  ;;
arm-64-linux)
  IMAGE=quay.io/pypa/manylinux_2_28_aarch64
  TOOLCHAIN=arm-64-linux.cmake
  ;;
arm-32-linux)
  IMAGE=quay.io/pypa/manylinux_2_31_armv7l
  TOOLCHAIN=arm-32-linux.cmake
  ;;
*)
  echo "Unknown platform: $PLATFORM" >&2
  echo "Supported: x86-64-linux, x86-32-linux, arm-64-linux, arm-32-linux" >&2
  exit 1
  ;;
esac

DIST="dist/$PLATFORM"
echo "Building halide-llvm wheel for $PLATFORM (ref: $REF)"
echo "Image: $IMAGE"
echo "Output: $DIST/"

mkdir -p "$DIST"

docker run --rm \
  -v "$(pwd):/project" \
  -w /project \
  -e "HALIDE_LLVM_REF=$REF" \
  "$IMAGE" \
  bash -c "
    set -euo pipefail
    export PATH=/opt/python/cp312-cp312/bin:\$PATH

    pip wheel . -w $DIST/ -v \
      --config-settings=cmake.define.CMAKE_TOOLCHAIN_FILE=toolchains/$TOOLCHAIN

    pip install auditwheel
    auditwheel repair -w $DIST/ $DIST/*.whl
    rm -f $DIST/*-linux_*.whl

    echo
    echo 'Built wheels:'
    ls -lh $DIST/*.whl
  "
