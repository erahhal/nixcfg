{ pkgs, userParams, ... }:

{
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [
    gamescope
    protonup
  ];

  # home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
  #   home.packages = with pkgs; [
  #     gamescope
  #   ];
  # };
}
