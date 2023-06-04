args@{ config, pkgs, lib, hostParams, userParams, ... }:

with pkgs;
let
  i3-python-packages = python-packages: with python-packages; [
    # @TODO: this doesn't seem to be available to python scripts
    i3ipc
  ];
  lockcmd = "[[ !(-n $(pidof i3lock)) ]] && ${pkgs.i3lock}/bin/i3lock -c '#000000' --show-failed-attempts";
  python-with-i3-packages = python3.withPackages i3-python-packages;
in
{
  config = if hostParams.defaultSession == "none+i3" then {

    environment.systemPackages = [
      python-with-i3-packages
    ];

    services.dbus.packages = with pkgs; [ dconf ];

    programs.light.enable = true;

    fonts.fonts = with pkgs; [ terminus_font_ttf font-awesome ];

    services.xserver = {
      enable = true;

      desktopManager = {
        xterm.enable = false;
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
       ];
      };
    };

    # Not quite working yet
    /*
    systemd.services.i3wakelock = {
      before =  [ "sleep.target" "suspend.target" ];
      wantedBy = [ "sleep.target" "suspend.target" ];
      description = "i3 wake lock";

      serviceConfig = {
        User = userParams.username;
        Type = "forking";
        ExecStart = "${lockcmd}";
        Environment = "DISPLAY=:0";
      };
    };
    */

    home-manager.users.${userParams.username} = { pkgs, ... }: {
      imports = [
        ( import ../home/profiles/i3.nix (args // { launchAppsConfig = config.launchAppsConfig; lockcmd = lockcmd; }))
      ];
    };
  } else {};
}
