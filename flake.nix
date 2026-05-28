{
  description = "Standalone build of SVT-AV1 encoder (SvtAv1EncApp)";

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
  # Rename `SvtAv1EncApp` → `svt-av1` (with `SvtAv1EncApp` kept as a
  # symlink for upstream-name compatibility). unpins ships
  # `$out/bin/<pkg>` as the canonical entry point — both for `unpin
  # install` UX and for the CI verifier (`result/bin/${PKG}`).
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
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "svt-av1";
      build         = pkgs: rename (ulib.nativeFixes.svt-av1 pkgs.pkgsStatic);
      windowsBuild  = pkgs: rename (ulib.nativeFixes.svt-av1 (ulib.mingwStaticCross pkgs));
    };
}
