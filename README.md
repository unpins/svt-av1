# svt-av1

The [SVT-AV1](https://gitlab.com/AOMediaCodec/SVT-AV1) encoder — the Alliance for Open Media's production AV1 encoder. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/svt-av1/actions/workflows/svt-av1.yml/badge.svg)](https://github.com/unpins/svt-av1/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install svt-av1`.

It reads Y4M or raw YUV video and writes an AV1 stream in an `.ivf` file.

## Usage

Run the `svt-av1` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin svt-av1 -i input.y4m -b output.ivf
unpin svt-av1 -i input.y4m --preset 8 --crf 30 -b output.ivf
```

To install it onto your PATH:

```bash
unpin install svt-av1
```

`unpin install svt-av1` creates the `svt-av1` command, and `SvtAv1EncApp` as well — the name upstream uses.

## Build locally

```bash
nix build github:unpins/svt-av1
./result/bin/svt-av1 --version
```

Or run directly:

```bash
nix run github:unpins/svt-av1 -- --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/svt-av1/releases) page has standalone binaries for manual download.

## Build notes

- **Windows:** a single `.exe`, no companion DLLs.
- **No upstream features disabled** on any platform.
- **No man pages** — SVT-AV1 ships none; run with `--help`.
- **Very narrow video:** SVT-AV1 never finishes encoding frames 24 pixels wide or less. This is upstream behaviour and happens with any build of this version.
- **32-bit Linux (i686, armv7l):** on a machine with many cores, a large encode can stop before writing any video — SVT-AV1 starts one set of threads per core and runs out of the 4 GB a 32-bit program can address. `--lp 4` limits the threads and avoids it; the output is the same.
