{ config, inputs, lib, pkgs, userParams, ... }:
let
  hyprlockCommand = pkgs.callPackage ../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
in
{
  config = lib.mkIf (config.hostParams.desktop.defaultSession == "niri" || config.hostParams.desktop.multipleSessions) {
    services.displayManager.sessionPackages = [ pkgs.niri ];

    programs.niri = {
      enable = true;
    };

    environment.systemPackages = [
      pkgs.niri
    ];


    # Ignore lid switch, and let wm handle it using
    # the lid switch bindings below
    services.logind.lidSwitch = "ignore";


    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ../home/profiles/niri.nix
      ];

      # wayland.windowManager.hyprland = {
      #   settings = {
      #     bind = [
      #       (
      #         if config.hostParams.desktop.defaultLockProgram == "swaylock" then
      #           '',switch:on:Lid Switch,exec,${swayLockCommand} suspend''
      #         else
      #           '',switch:on:Lid Switch,exec,${hyprlockCommand} suspend''
      #       )
      #     ];
      #   };
      # };
    };
  };
}
