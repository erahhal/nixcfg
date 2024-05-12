{ pkgs, hostParams, userParams, ... }:
{
  imports = [
    ../hosts/${hostParams.hostName}/kanshi.nix
  ];

  # XDG portals - allow desktop apps to use resources outside their sandbox
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      ## Launching the WLR portal interferes with Hyprland screen sharing
      # xdg-desktop-portal-wlr # wlroots screen capture

      xdg-desktop-portal-gtk # gtk file dialogs

      ## seems to be already installed by hyperland
      # xdg-desktop-portal-hyprland # Hyprland specific
    ];
    wlr.enable = true;
    # gtkUsePortal = true;
  };

  # Automated monitor, workspace, layout config
  systemd.user.services.kanshi = {
    description = "Kanshi output autoconfig ";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      # kanshi doesn't have an option to specifiy config file yet, so it looks
      # at .config/kanshi/config
      ExecStart = ''
        ${pkgs.kanshi}/bin/kanshi
      '';
      RestartSec = 5;
      Restart = "always";
    };
  };


  ## Polkit supports GUI auth for restarting systemd services

  ## KDE polkit is still using XWayland, use Gnome instead
  # systemd.user.services.polkit-kde-authentication-agent-1 = {
  #   description = "polkit-kde-authentication-agent-1";
  #   wantedBy = [ "graphical-session.target" ];
  #   wants = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
  #     Restart = "on-failure";
  #     RestartSec = 1;
  #     TimeoutStopSec = 10;
  #   };
  # };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  ## Supposedly needed to use home manager to configure sway, but it's been working find without this
  security.polkit.enable = true;

  services.dbus.packages = with pkgs; [ dconf ];

  # Enable XDG Autostart
  services.xserver.desktopManager.runXdgAutostartIfNone = true;

  # Enables brightness and volume functions
  # Requires user be part of "video" group
  programs.light.enable = true;

  fonts.packages = with pkgs; [ terminus_font_ttf font-awesome ];

  environment.systemPackages = with pkgs; [
    egl-wayland
  ];

  # Make sure that /etc/pam.d/swaylock is added.
  # Otherwise swaylock doesn't unlock.
  security.pam.services.swaylock = {};

  home-manager.users.${userParams.username} = {
    home.sessionVariables = {
      ## @TODO: This should def be loaded at runtime.
      #         This is cofigured in hyprland config.
      ## @TODO: Verify that it's overriden in hyprland.
      XDG_CURRENT_DESKTOP = "sway";

      # ---------------------------------------------------------------------------
      # Wayland-related
      # ---------------------------------------------------------------------------
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_WEBRENDER = "1";
      WLR_DRM_NO_MODIFIERS = "1";

      # CLUTTER_BACKEND = "wayland";
      ## Sway doesn't load with this
      # WLR_RENDERER = "vulkan";
      ## Steam doesn't work with this enabled
      # SDL_VIDEODRIVER = "wayland";

      ## using "wayland" makes menus disappear in kde apps
      ## UPDATE: Menus seem to work, but some buttons don't work unless the window is floated. (Seems to be fixed by setting QT_AUTO_SCREEN_SCALE_FACTOR=1? )
      ##         and borders between elements are sometimes transparent, showing the background.
      QT_QPA_PLATFORM = "wayland";
      # QT_QPA_PLATFORM = "xcb";

      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      XDG_SESSION_TYPE = "wayland";

      # Used to inform discord and other apps that we are using wayland
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };
}
