{ pkgs, ... }:

# trunk is used as the multimc maintainer tries to block
# prismlauncher, so the latest must be used.
# If trunk no longer works, try the following:
# https://github.com/PolyMC/PolyMC/blob/develop/packages/nix/NIX.md

let
  prismlauncher-nvidia = pkgs.writeShellScriptBin "prismlauncher" ''
    nvidia-offload ${pkgs.trunk.prismlauncher}/bin/prismlauncher
  '';
in
pkgs.symlinkJoin {
  name = "prismlauncher-nvidia";
  paths = [
    # Additional JDKs
    pkgs.jdk17

    # 1.19 fails without this package
    pkgs.flite

    prismlauncher-nvidia
  ];
}
