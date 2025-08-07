#!/usr/bin/env bash

set -eo pipefail

export CCACHE_BASEDIR=$PWD
export CCACHE_NOHASHDIR=true
export CCACHE_SLOPPINESS=include_file_ctime,include_file_mtime,pch_defines,time_macros

export CMAKE_C_COMPILER_LAUNCHER=ccache
export CMAKE_CXX_COMPILER_LAUNCHER=ccache

export CFLAGS="-Xclang -fno-pch-timestamp -fdebug-prefix-map=$PWD=."
export CXXFLAGS="$CFLAGS"

export TMPDIR=$PWD/build/tmp
mkdir -p "$TMPDIR"

export UV_NO_BUILD_ISOLATION=1

uv pip install .
