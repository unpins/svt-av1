# svt-av1

Standalone build of the [SVT-AV1](https://gitlab.com/AOMediaCodec/SVT-AV1) encoder — the Alliance for Open Media reference AV1 encoder.

[![CI](https://github.com/unpins/svt-av1/actions/workflows/svt-av1.yml/badge.svg)](https://github.com/unpins/svt-av1/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

The shipped binary is named `SvtAv1EncApp` (upstream convention). It accepts Y4M or raw YUV input and writes an AV1 bitstream (`.ivf`).

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin svt-av1
```

Or run without installing:

```bash
unpin run svt-av1
```

## Build locally

```bash
nix build github:unpins/svt-av1
./result/bin/SvtAv1EncApp --version
```

Or run directly:

```bash
nix run github:unpins/svt-av1 -- --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/svt-av1/releases) page has standalone binaries for manual download.

## Build notes

- **Windows variant:** `mingw` (cross from Linux). No POSIX gaps — the encoder is plain C with its own thread abstraction.
- **`-DSVT_AV1_LTO=OFF`**: nixpkgs defaults to `-DSVT_AV1_LTO=ON`, which leaves the static archive carrying only LTO IR (`__gnu_lto_slim`). Non-LTO consumers (ffmpeg's `pkg-config` link probe via `ld.bfd` without the LTO plugin) can't resolve any symbol and fail with `undefined reference to svt_av1_enc_init_handle`. The override lives in [`nix-lib/native-overlay/svt-av1.nix`](https://github.com/unpins/nix-lib/blob/main/native-overlay/svt-av1.nix) so it applies uniformly across all platforms.
- **No embedded resources.** All encoder data is compiled in; nothing is loaded from disk at runtime.
- **No upstream features disabled.** Same encode capabilities on every platform.
