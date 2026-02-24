"""
Module of global project settings.
"""

load("//constraints/amd64:defs.bzl", "AMD64_VARIANTS")
load("//constraints/arm64:defs.bzl", "ARM64_VARIANTS")

# Rust toolchains for different architectures.
RUST_PLATFORMS_PER_ARCH = dict(
    [
        ("arm64", "//:linux-aarch64"),
        ("amd64", "//:linux-x86_64"),
    ] +
    [("arm64_%s" % v, "//:linux-aarch64-%s" % v) for v in ARM64_VARIANTS] +
    [("amd64_%s" % v, "//:linux-x86_64-%s" % v) for v in AMD64_VARIANTS],
)

_BUILD_FLAGS_DEBUG = [
    "-Copt-level=0",
]

_BUILD_FLAGS_RELEASE = [
    "-Ccodegen-units=1",
    "-Clto=thin",
    "-Copt-level=3",
    "-Cpanic=abort",
    "-Cstrip=symbols",
]

# Selects the right -Ctarget-cpu for x86-64 microarchitecture levels.
# Falls back to no flag (baseline x86-64) when no constraint is set.
_AMD64_MICROARCH_FLAGS = select(dict(
    [("//:amd64_%s" % v, ["-Ctarget-cpu=x86-64-%s" % v]) for v in AMD64_VARIANTS] +
    [("//conditions:default", [])],
))

# Selects the right -Ctarget-feature for AArch64 ISA versions.
# Falls back to no flag (baseline ARMv8.0-A) when no constraint is set.
_ARM64_MICROARCH_FLAGS = select(dict(
    [("//:arm64_%s" % v, ["-Ctarget-feature=+%s" % v.replace("_", ".")]) for v in ARM64_VARIANTS] +
    [("//conditions:default", [])],
))

RUST_BUILD_FLAGS = select({
    "//:optimized": _BUILD_FLAGS_RELEASE,
    "//conditions:default": _BUILD_FLAGS_DEBUG,
})

RUST_BUILD_FLAGS_PER_ARCH = dict(
    [
        ("arm64", RUST_BUILD_FLAGS),
        ("amd64", RUST_BUILD_FLAGS),
    ] +
    [("arm64_%s" % v, RUST_BUILD_FLAGS + _ARM64_MICROARCH_FLAGS) for v in ARM64_VARIANTS] +
    [("amd64_%s" % v, RUST_BUILD_FLAGS + _AMD64_MICROARCH_FLAGS) for v in AMD64_VARIANTS],
)
