{ inputs, pkgs, ... }:
let
  caelestia-shell = inputs.caelestia-shell.packages.${pkgs.system}.default.override {
    withCli = true;
  };
in
{
  # home.packages = [
  #    caelestia-shell
  # ];

  # programs.quickshell = {
  #   enable = true;
  #   package = caelestia-shell;
  #   systemd.enable = true;
  # };

  home.file."Wallpaper".source = ../../wallpapers;

  programs.caelestia = {
    enable = true;
    # systemd = {
    #   enable = false; # if you prefer starting from your compositor
    #   target = "graphical-session.target";
    # };
    systemd.enable = true;
    settings = {
      general = {
        apps = {
          terminal = [ "foot" ];
          audio =[ "pavucontrol" ];
        };
      };
      bar.status = {
        showBattery = true;
      };
      paths.wallpaperDir = "~/Wallpaper";
    };
    environment = [];
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };

  # wayland.windowManager.hyprland = {
  #   settings = {
  #     exec-once = [
  #       "caelestia-shell -d"
  #     ];
  #   };
  # };
}
