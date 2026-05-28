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
  outputs = { self, unpins-lib }:
    let ulib = unpins-lib.lib; in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "svt-av1";
      binName = "SvtAv1EncApp";
      build         = pkgs: ulib.nativeFixes.svt-av1 pkgs.pkgsStatic;
      windowsBuild  = pkgs: ulib.nativeFixes.svt-av1 (ulib.mingwStaticCross pkgs);
    };
}
