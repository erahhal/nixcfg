{ config, inputs, lib, pkgs, userParams, ... }:
let
  hyprlockCommand = pkgs.callPackage ../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
  niri-script = pkgs.writeShellScriptBin "niri" ''
    export NIRI_SOCKET=$(${pkgs.findutils}/bin/find /run/user/$(id -u) -name "niri.wayland-*.sock" 2>/dev/null | head -1)
     ${pkgs.niri}/bin/niri "$@"
  '';
in
{
  config = lib.mkIf (config.hostParams.desktop.defaultSession == "niri" || config.hostParams.desktop.multipleSessions) {
    services.displayManager.sessionPackages = [ pkgs.niri ];

    programs.niri = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      niri-script
      xwayland-satellite  # This may or may not be available depending on your channel
      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
      nautilus  # Required for GNOME portal
      pipewire
      wireplumber
      gnome-keyring
    ];

    # services.dbus.implementation = "broker";

    xdg.portal = {
      enable = true;
      config = {
        #common.default = "*";
        common = {
          default = [ "gtk"];
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
          "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
          # "org.freedesktop.impl.portal.ScreenCast" = "wlr";
          # "org.freedesktop.impl.portal.RemoteDesktop" = "wlr";
        };
      };
      # xdgOpenUsePortal = true;
      # configPackages = [config.programs.niri.package];
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        xdg-desktop-portal
        gnome-keyring
        # xdg-desktop-portal-wlr
      ];
    };

    # systemd.user.services.xdg-desktop-portal-gnome = {
    #   environment = {
    #     GDK_BACKEND = "wayland";
    #     WAYLAND_DISPLAY = "wayland-1";
    #   };
    # };

    # Ignore lid switch, and let wm handle it using
    # the lid switch bindings below
    services.logind.lidSwitch = "ignore";

    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ../home/profiles/niri.nix
      ];

      ## These need to be installed as well as the ones at the system level
      ## because xdg-desktop-portal is going to look in
      ## /etc/profiles/per-user/<username>/share/xdg-desktop-portal/portals
      ## first, which will exist because hyprland.portal is there as well.
      ## Installing here adds these portals there as well.
      home.packages = with pkgs; [
        # xdg-desktop-portal-wlr
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        xdg-desktop-portal
        gnome-keyring
      ];

      # xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
      #   [preferred]
      #   default=gtk
      #   org.freedesktop.impl.portal.FileChooser=gtk;
      #   org.freedesktop.impl.portal.ScreenCast=gnome;
      #   org.freedesktop.impl.portal.Screenshot=gnome;
      #   org.freedesktop.impl.portal.RemoteDesktop=gnome;
      # '';
      #
      # xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
      #   [preferred]
      #   default=gtk
      #   org.freedesktop.impl.portal.FileChooser=gtk;
      #   org.freedesktop.impl.portal.ScreenCast=gnome;
      #   org.freedesktop.impl.portal.Screenshot=gnome;
      #   org.freedesktop.impl.portal.RemoteDesktop=gnome;
      # '';

      # xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
      #   [preferred]
      #   default=gtk
      #   org.freedesktop.impl.portal.ScreenCast=gnome
      #   org.freedesktop.impl.portal.Screenshot=gnome
      # '';

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
