{ config, pkgs, hostParams, userParams, ... }:

{
  imports = [ ] ++ (if hostParams.defaultSession == "sway" then [
    ../hosts/${hostParams.hostName}/kanshi.nix
    # ../overlays/sway-with-dbus.nix
    # ../overlays/sway-with-nvidia-patches.nix
    # ../overlays/sway-with-input-methods.nix
  ] else []);

  config = if hostParams.defaultSession == "sway" then {

    # XDG portals - allow desktop apps to use resources outside their sandbox
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr # wlroots screen capture
        xdg-desktop-portal-gtk # gtk file dialogs
      ];
      wlr.enable = true;
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

    systemd.user.services.polkit-kde-authentication-agent-1 = {
      description = "polkit-kde-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    ## Supposedly needed to use home manager to configure sway, but it's been working find without this
    security.polkit.enable = true;

    services.dbus.packages = with pkgs; [ dconf ];

    # Enables brightness and volume functions
    # Requires user be part of "video" group
    programs.light.enable = true;

    # The NixOS option 'programs.sway.enable' is needed to make swaylock work,
    # since home-manager can't set PAM up to allow unlocks, along with some
    # other quirks.
    programs.sway = {
      enable = true;
      # nVidia support
      extraOptions = [
        "--unsupported-gpu"
      ];
      wrapperFeatures = {
        base = true; # run extraSessionCommands
        gtk = true;
      };
    };

    fonts.packages = with pkgs; [ terminus_font_ttf font-awesome ];

    environment.systemPackages = with pkgs; [
      egl-wayland
    ];

    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      imports = [
        ( import ../home/profiles/sway.nix (args // {
          launchAppsConfig = config.launchAppsConfigSway;
          hostParams = hostParams;
        }))
      ];
    };
  } else {};
}
