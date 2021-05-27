let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
  futhark_shell = import ./futhark/shell.nix;
in

let pythonEnv = (pkgs.python37.withPackages (ps: [
      ps.numpy
      ps.matplotlib
    ])).override (args: { ignoreCollisions = true; });
in
pkgs.mkShell {
  buildInputs = [
    pythonEnv
    futhark_shell.buildInputs
    pkgs.intel-compute-runtime
    pkgs.opencl-headers
    pkgs.ocl-icd
  ];
}
