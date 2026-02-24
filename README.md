# Rust + Bazel Cross-Compilation Example (LLVM + musl)

Cross-compile Rust binaries for Linux using **LLVM/Clang/lld** with **musl libc** sysroots, producing fully **static** Linux binaries with no runtime dependencies.

## Why LLVM + musl?

- **LLVM/Clang/lld** -- fast linking, native cross-compilation, single toolchain for all targets
- **musl libc** -- designed for static linking, no IFUNC/IRELATIVE relocations, no glibc `--defsym` workarounds
- **Static binaries** -- zero runtime dependencies, ideal for containers and scratch Docker images
- **mimalloc** -- high-performance allocator, compiles cleanly against musl

## Build

### Host build (macOS / native)

```bash
bazel build -c opt //rust/hello_world
```

### Cross-compile static Linux binaries

```bash
# x86_64 (baseline)
bazel build -c opt //rust/hello_world:hello_world_static_amd64

# x86_64-v3 (AVX2, most modern servers)
bazel build -c opt //rust/hello_world:hello_world_static_amd64_v3

# aarch64 (Graviton, Ampere)
bazel build -c opt //rust/hello_world:hello_world_static_arm64
```

### Build all targets at once

```bash
bazel build -c opt //...
```

## Architecture variants

### x86-64 microarchitecture levels

| Target     | CPU flag  | Instruction sets         |
| ---------- | --------- | ------------------------ |
| `amd64`    | baseline  | SSE2                     |
| `amd64_v2` | x86-64-v2 | +SSE4.2, +POPCNT, +SSSE3 |
| `amd64_v3` | x86-64-v3 | +AVX2, +FMA, +BMI1/2     |
| `amd64_v4` | x86-64-v4 | +AVX-512                 |

### AArch64 ISA versions

| Target        | Feature  | Examples                 |
| ------------- | -------- | ------------------------ |
| `arm64`       | baseline | ARMv8.0-A                |
| `arm64_v8_2a` | +v8.2a   | Graviton 2, Ampere Altra |
| `arm64_v8_4a` | +v8.4a   | Graviton 3, Neoverse V1  |
| `arm64_v9a`   | +v9a     | Graviton 4, Neoverse V2  |

See `constraints/arm64/defs.bzl` for the full list (v8.1a through v9.6a).

## Build modes

| Flag     | Mode      | Description                  |
| -------- | --------- | ---------------------------- |
| (none)   | fastbuild | No optimizations             |
| `-c dbg` | debug     | Debug info, no optimizations |
| `-c opt` | optimized | LTO, stripped, `-O3`         |

## Project structure

```text
.
├── MODULE.bazel           # Root Bazel module (rules_rust, toolchains_llvm)
├── rust.MODULE.bazel      # Rust/LLVM toolchains, musl sysroots, crate deps
├── BUILD                  # Platform definitions
├── settings.bzl           # Rust compiler flags
├── constraints/
│   ├── amd64/             # x86-64 microarch levels (v2, v3, v4)
│   └── arm64/             # AArch64 ISA versions (v8.1a – v9.6a)
├── rust/
│   └── hello_world/       # Example binary (mimalloc + tokio)
├── Cargo.toml             # Workspace manifest
└── Cargo.lock             # Dependency lock
```

## Dependencies

| Component       | Version                        |
| --------------- | ------------------------------ |
| Bazel           | 9.0.0                          |
| rules_rust      | 0.68.1                         |
| toolchains_llvm | 1.6.0                          |
| LLVM            | 21.1.8                         |
| Rust            | 1.93.1 (edition 2024)          |
| musl sysroot    | 1.2.5 (kernel headers 6.12.73) |

## Comparison with glibc variant

This project is the **musl** counterpart of [rust-bazel-cross-compile-example-llvm](https://github.com/amsokol/rust-bazel-cross-compile-example-llvm) (which uses glibc sysroots). Key differences:

|                | LLVM + glibc                                         | LLVM + musl                |
| -------------- | ---------------------------------------------------- | -------------------------- |
| Sysroot        | Debian Trixie                                        | Custom musl 1.2.5          |
| Static linking | Requires `--defsym` workaround for lld IRELATIVE bug | Works cleanly              |
| Binary size    | Larger (glibc is bigger)                             | Smaller                    |
| Runtime deps   | May need `ld-linux-*.so`                             | None (fully static)        |
| LTO            | `-Clink-arg=-flto` (linker plugin)                   | `-Clto=thin` (Rust-native) |
