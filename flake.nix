{
  description = "SVT-AV1 encoder (SvtAv1EncApp) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Single CLI upstream (`SvtAv1EncApp`). nixpkgs' `pkgsStatic.svt-av1` is
  # already cross-clean on linux / darwin / mingw; the only override is the
  # shared `nativeFixes.svt-av1` fix (drop `-DSVT_AV1_LTO=ON`, which leaves
  # the static archive as LTO-IR only — non-LTO consumers like ffmpeg's
  # pkg-config probe can't resolve the symbols). See
  # nix-lib/native-overlay/svt-av1.nix.
  #
  # Rename `SvtAv1EncApp` → `svt-av1`: the shipped artifact is taken from
  # `$out/bin/<pkg>`, and without the rename the build stops at
  # `unpinEmbedWrap: no binary <svt-av1>`. The symlink does not reach the
  # artifact; the upstream name reaches users as the `SvtAv1EncApp` alias that
  # `unpin install` creates.
  outputs = { self, unpins-lib }:
    let
      ulib = unpins-lib.lib;
      rename = drv: drv.overrideAttrs (oa: {
        postInstall = (oa.postInstall or "") + ''
          exe=$(find "$out/bin" -maxdepth 1 -name 'SvtAv1EncApp*' -print -quit)
          ext=''${exe##*SvtAv1EncApp}
          mv "$exe" "$out/bin/svt-av1$ext"
          ln -s "svt-av1$ext" "$out/bin/SvtAv1EncApp$ext"
        '';
      });

      # The smoke is `--version`, which passes on a binary that can't encode a
      # frame. This encodes for real wherever the build machine can run the
      # result: a lossless round trip decoded by dav1d must give back the input
      # bytes, and stdin/stdout must give the same stream as files. The input is
      # 64x64 because SVT-AV1 itself never finishes on frames 24 pixels wide or
      # less (the nixpkgs glibc build hangs the same way).
      withRoundTrip = pkgs: drv: drv.overrideAttrs (old: {
        doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
        nativeInstallCheckInputs = (old.nativeInstallCheckInputs or [ ])
          ++ [ (pkgs.buildPackages.dav1d.override { withTools = true; }) ];
        installCheckPhase = ''
          runHook preInstallCheck
          enc="$out/bin/svt-av1"
          LC_ALL=C awk 'BEGIN {
            for (f = 0; f < 3; f++) {
              for (i = 0; i < 4096; i++) printf "%c", (i * 7 + f * 13 + int(i / 64) * 5) % 256
              for (i = 0; i < 2048; i++) printf "%c", (i * 3 + f * 29) % 256
            }
          }' > p.yuv
          test "$(wc -c < p.yuv)" -eq 18432 || { echo "probe input has the wrong size"; exit 1; }

          "$enc" -i p.yuv -w 64 -h 64 --preset 10 --lossless 1 -b p.ivf
          dav1d -q -i p.ivf -o back.yuv
          cmp p.yuv back.yuv || { echo "lossless AV1 round trip is not exact"; exit 1; }

          "$enc" -i - -w 64 -h 64 --preset 10 --lossless 1 -b - < p.yuv > piped.ivf
          cmp p.ivf piped.ivf || { echo "encoding through stdin/stdout differs from files"; exit 1; }

          echo "installCheck: lossless AV1 round trip exact, stdin/stdout match files"
          runHook postInstallCheck
        '';
      });
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "svt-av1";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        # The `.exe` on the engine too, not the nixpkgs mingw-gcc cross.
        windows = true;
        programs = [{
          # SVT-AV1 installs no man page.
          name = "SvtAv1EncApp";
          noMan = true;
        }];
      };
      # `SvtAv1EncApp --version` prints `SVT-AV1 vX.Y.Z (release)` and exits 0 on
      # every ABI including the Windows runner. Without this the CI smoke job is
      # skipped outright and nothing ever runs the binary.
      smoke = [ "--version" ];
      smokePattern = "SVT-AV1 v[0-9]+[.][0-9]+";
      # SVT-AV1's LICENSE.md is the Clear BSD License; the AOMedia patent grant
      # nixpkgs also lists is a separate patent license, not the copyright one.
      license = "BSD-3-Clause-Clear";
      build         = pkgs: withRoundTrip pkgs (rename (ulib.nativeFixes.svt-av1 pkgs.pkgsStatic));
      windowsBuild  = pkgs: rename (ulib.nativeFixes.svt-av1 (ulib.mingwStaticCross pkgs));
    };
}
