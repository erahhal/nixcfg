{ pkgs, userParams, ... }:

{
  imports = [
    ../overlays/steam-nvidia.nix
  ];

  programs.steam.enable = true;
}
