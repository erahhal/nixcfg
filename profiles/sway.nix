args@{ config, pkgs, lib, hostParams, userParams, ... }:

{
  imports = [ ] ++ (if hostParams.defaultSession == "sway" then [
    ../hosts/${hostParams.hostName}/kanshi.nix
  ] else []);

  config = if hostParams.defaultSession == "sway" then {

    ## Chromium Wayland support
    # nixpkgs.config.chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
    ## OR
    # nixpkgs.config.chromium.commandLineArgs = "--ozone-platform-hint=auto";

    ## Full screen sharing support
    ## This disables the ability to share windows, so probably better to just use:
    ## chrome://flags/#enable-webrtc-pipewire-capturer
    # nixpkgs.config.chromium.commandLineArgs = "--enable-features=WebRTCPipeWireCapturer";

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.sway = {
      description = "Sway - Wayland window manager";
      documentation = [ "man:sway(5)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
      # We explicitly unset PATH here, as we want it to be set by
      # systemctl --user import-environment in startsway
      environment.PATH = lib.mkForce null;
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.dbus}/bin/dbus-run-session bash -l -c ${pkgs.sway}/bin/sway
        '';
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

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

    services.dbus.packages = with pkgs; [ dconf ];

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
