let
  sources = import ./futhark/nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  futhark_shell = import ./futhark/shell.nix;

in let
  pythonEnv =
    (pkgs.python3.withPackages (ps: [ ps.numpy ps.matplotlib ])).override
    (args: { ignoreCollisions = true; });
in futhark_shell.overrideAttrs (oldAttrs: rec {
  buildInputs = oldAttrs.buildInputs
    ++ [ pythonEnv pkgs.moreutils pkgs.jq ];
})
