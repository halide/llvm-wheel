"""Dump everything relevant to wheel platform tag computation."""

import os
import struct
import sys
import sysconfig

print(f"sys.platform = {sys.platform!r}")
print(f"struct.calcsize('P') = {struct.calcsize('P')} (pointer size in bytes)")
print(f"sysconfig.get_platform() = {sysconfig.get_platform()!r}")
print()

print("=== VSCMD environment variables ===")
for key, val in sorted(os.environ.items()):
    if "VSCMD" in key.upper():
        print(f"  {key} = {val!r}")

print()
print("=== scikit-build-core platform detection ===")
try:
    from scikit_build_core.builder.sysconfig import (
        TARGET_TO_PLAT,
        get_host_platform,
        get_platform,
    )

    print(f"  TARGET_TO_PLAT = {TARGET_TO_PLAT!r}")
    print(f"  get_host_platform() = {get_host_platform()!r}")
    print(f"  get_platform(os.environ) = {get_platform(os.environ)!r}")
except ImportError:
    print("  (scikit-build-core not installed, skipping)")

print()
print("=== packaging.tags ===")
try:
    import packaging.tags

    tags = list(packaging.tags.sys_tags())
    platforms = sorted({t.platform for t in tags})
    print(f"  Number of tags: {len(tags)}")
    print(f"  Best tag: {tags[0]}")
    print(f"  Unique platforms ({len(platforms)}): {platforms[:10]}...")
except ImportError:
    print("  (packaging not installed, skipping)")

print()
print("=== WheelTag.compute_best() ===")
try:
    from scikit_build_core.builder.builder import archs_to_tags, get_archs
    from scikit_build_core.builder.wheel_tag import WheelTag

    archs = get_archs(os.environ)
    arch_tags = archs_to_tags(archs)
    print(f"  get_archs(os.environ) = {archs!r}")
    print(f"  archs_to_tags(archs) = {arch_tags!r}")

    tag = WheelTag.compute_best(arch_tags, py_api="py3")
    print(f"  WheelTag.compute_best(arch_tags, py_api='py3') = {tag!r}")
except Exception as e:
    print(f"  Error: {e}")
