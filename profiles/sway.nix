args@{ config, pkgs, lib, hostParams, userParams, ... }:

{
  imports = [ ] ++ (if hostParams.defaultSession == "sway" then [
    ../hosts/${hostParams.hostName}/kanshi.nix
    # ../overlays/sway-with-dbus.nix
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
      };
      ## This doesn't appear to do anything
      # extraSessionCommands = ''
      # '';
      extraPackages = with pkgs; [
        # @TODO: this is repeated - figure out where it makes the most sense to live
        kanshi
      ];
    };

    fonts.fonts = with pkgs; [ terminus_font_ttf font-awesome ];

    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ( import ../home/profiles/sway.nix (args // { launchAppsConfig = config.launchAppsConfig; }))
      ];
    };
  } else {};
}
