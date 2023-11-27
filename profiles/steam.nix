{ pkgs, userParams, ... }:

{
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    protonup
  ];

  # home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
  #   home.packages = with pkgs; [
  #     gamescope
  #   ];
  # };
}
