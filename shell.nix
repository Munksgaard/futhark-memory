let
  sources = import ./futhark/nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  futhark_shell = import ./futhark/shell.nix;
in futhark_shell.overrideAttrs (oldAttrs: rec {
  buildInputs =
    oldAttrs.buildInputs ++
    [ pkgs.python3Packages.matplotlib
      pkgs.moreutils
      pkgs.jq
      pkgs.texlive.combined.scheme-full];
})
