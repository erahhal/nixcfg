{ config, inputs, lib, pkgs, userParams, ... }:
let
  niri-script = pkgs.writeShellScriptBin "niri" ''
    export NIRI_SOCKET=$(${pkgs.findutils}/bin/find /run/user/$(id -u) -name "niri.wayland-*.sock" 2>/dev/null | head -1)
     ${pkgs.niri}/bin/niri "$@"
  '';
  niri-sddm = pkgs.writeShellScriptBin "niri-sddm" ''
    # Brief delay to let SDDM release the device
    sleep 1
    export __GL_SHADER_DISK_CACHE=1
    cache_root=''${XDG_CACHE_HOME:-$HOME/.cache}
    cache_dir="$cache_root/nvidia-shader-cache"
    mkdir -p "$cache_dir"
    export __GL_SHADER_DISK_CACHE_PATH="$cache_dir"
    exec niri --session
  '';
in
{
  config = lib.mkIf (config.hostParams.desktop.defaultSession == "niri" || config.hostParams.desktop.multipleSessions) {
    ## Not using as services.displayManager.sessionPackages needs to be overridden
    # programs.niri = {
    #   enable = true;
    # };

    services.displayManager.sessionPackages = [
      (pkgs.runCommand "niri-session" {
        passthru.providedSessions = [ "niri" ];
      } ''
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/niri.desktop << EOF
        [Desktop Entry]
        Name=Niri
        Comment=Niri Wayland Compositor
        Exec=${niri-sddm}/bin/niri-sddm
        Type=Application
      '')
    ];

    services.gnome.gnome-keyring.enable = lib.mkDefault true;

    security = {
      polkit.enable = true;
      pam.services.swaylock = { };
    };

    programs = {
      niri.enable = true;
      dconf.enable = true;
      xwayland.enable = true;
    };

    # Window manager only sessions (unlike DEs) don't handle XDG
    # autostart files, so force them to run the service
    services.xserver.desktopManager.runXdgAutostartIfNone = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      niri-script
      evremap
      libinput
      xwayland-satellite  # This may or may not be available depending on your channel
      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      # xdg-desktop-portal-wlr
      nautilus  # Required for GNOME portal
      pipewire
      wireplumber
      gnome-keyring
    ];

    xdg.portal = {
      enable = true;
      configPackages = [ config.programs.niri.package ];
      config = {
        #common.default = "*";
        common = {
          default = [ "gtk"];
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
          "org.freedesktop.impl.portal.Settings" = "gtk;gnome;";
          "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
          "org.freedesktop.impl.portal.InputCapture" = "gnome";
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

    # Ignore lid switch, and let wm handle it using
    # the lid switch bindings below
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    ## See: https://yalter.github.io/niri/Nvidia.html
    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" = {
      text = builtins.toJSON {
        rules = [{
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }];
        profiles = [{
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [{
            key = "GLVidHeapReuseRatio";
            value = 0;
          }];
        }];
      };
    };

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
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        # xdg-desktop-portal-wlr
        xdg-desktop-portal
        gnome-keyring
      ];
    };
  };
}
