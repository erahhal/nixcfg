{ pkgs ? import <nixpkgs> {} }:
(pkgs.buildFHSEnv {
  name = "vscode";
  targetPkgs = pkgs: with pkgs;
    [
      libSM
      gtk2-x11
      gcc
    ];
  multiPkgs = pkgs: with pkgs;
    [
      udev
    ];
}).env
# pkgs.mkShell {
#   packages = [ pkgs.udev ];
#   shellHook = ''export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [
#     pkgs.udev
#   ]}"'';
# }
