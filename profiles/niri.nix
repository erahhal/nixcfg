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

    environment.systemPackages = with pkgs; [
      niri
      xwayland-satellite  # This may or may not be available depending on your channel
      xdg-desktop-portal
      xdg-desktop-portal-gnome
      nautilus  # Required for GNOME portal
      pipewire
      gnome-keyring
    ];

    xdg.portal = {
      enable = true;
      # config = {
      #   #common.default = "*";
      #   common = {
      #     default = ["gnome" "gtk"];
      #     "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      #     "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      #     "org.freedesktop.impl.portal.FileChooser" = "gtk";
      #   };
      # };
      configPackages = [config.programs.niri.package];
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        gnome-keyring
      ];
    };

    systemd.user.services.xdg-desktop-portal-gnome = {
      environment = {
        GDK_BACKEND = "wayland";
        WAYLAND_DISPLAY = "wayland-1";
      };
    };

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
