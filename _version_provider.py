"""
Dynamic version provider for halide-llvm.

Reads HALIDE_LLVM_REF from the environment and converts it to a PEP 440 version:
  - llvmorg-X.Y.Z  -> X.Y.Z
  - main           -> X.0.0.dev0+g<sha> (where X is the next major version)

Environment variables:
  HALIDE_LLVM_REF           - Required. The LLVM git ref (e.g., "llvmorg-21.1.6" or "main")
  HALIDE_LLVM_MAJOR_VERSION - Required for main builds. The upcoming LLVM major version.
  HALIDE_LLVM_SHA           - Optional. The LLVM commit SHA for dev builds.
"""

from __future__ import annotations

import os
import re
from typing import Any, Mapping


def dynamic_metadata(
    field: str,
    settings: Mapping[str, Any] | None = None,
) -> str:
    if field != "version":
        msg = f"Only 'version' is supported, not {field!r}"
        raise RuntimeError(msg)

    ref = os.environ.get("HALIDE_LLVM_REF", "")

    # Release tag: llvmorg-X.Y.Z -> X.Y.Z
    match = re.match(r"^llvmorg-(\d+\.\d+\.\d+)$", ref)
    if match:
        return match.group(1)

    # Development build from main
    if ref == "main":
        major = os.environ.get("HALIDE_LLVM_MAJOR_VERSION")
        if not major:
            msg = "HALIDE_LLVM_MAJOR_VERSION must be set when HALIDE_LLVM_REF=main"
            raise RuntimeError(msg)
        sha = os.environ.get("HALIDE_LLVM_SHA", "unknown")[:12]
        return f"{major}.0.0.dev0+g{sha}"

    # No ref specified or unrecognized format
    if not ref:
        msg = (
            "HALIDE_LLVM_REF environment variable must be set. "
            "Examples: 'llvmorg-21.1.6', 'main'"
        )
        raise RuntimeError(msg)

    # Unknown ref format - produce a valid but identifiable version
    safe_ref = re.sub(r"[^a-zA-Z0-9]", "", ref)[:20]
    return f"0.0.0.dev0+{safe_ref}"
