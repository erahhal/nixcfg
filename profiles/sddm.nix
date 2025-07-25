{ config, pkgs, lib, userParams, ... }:

## Available Themes
# "abstractdark"; # good, needs layout fix
# "adapta"; # really nice
# "aerial"; # should be animated but isn't
# "arc"; # same as adapta with multiple layouts
# "chili"; # decent
# "goodnight"; # cute
# "lain-wired"; # edgey animated
# "mount"; # great mountain background
# "slice"; # retro-futuristic interface
# "sober"; # good minimal with cursive
# "suger-dark"; # decent
# "zune"; # OK, some layout issues

let
  sddm-themes = pkgs.callPackage ../pkgs/sddm-themes {};
  # sddm-astronaut = pkgs.sddm-astronaut.override {
  #   embeddedTheme = "pixel_sakura";
  #   themeConfig = if lib.hasSuffix "sakura_static.png" config.stylix.image then
  #     { }
  #   else {
  #     Background = "${toString config.stylix.image}";
  #   };
  # };
in
{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "sddm") {

    #---------------------------------------------------------------------------
    # Using Xorg
    #---------------------------------------------------------------------------

    ## Does not work to change SDDM cursor size
    # environment.variables = {
    #   XCURSOR_SIZE = "64";
    # };

    ## This is the only thing that seems to change the SDDM cursor when using X11. Not needed for Wayland.
    services.xserver.upscaleDefaultCursor = true; # default false

    services.xserver = {
      enable = true;
      dpi = config.hostParams.desktop.dpi;
    };

    # services.xserver = {
    #   enable = false;
    #   displayManager = {
    #     ## Does not work to change SDDM cursor theme or size
    #     setupCommands = ''
    #       # export XCURSOR_SIZE=64
    #       ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic/cursors/left_ptr 128 &disown
    #       ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
    #         Xft.dpi: ${toString config.hostParams.desktop.dpi}
    #         Xcursor.theme: Bibata-Modern-Classic
    #         Xcursor.size: 64
    #       EOF
    #     '';
    #     ## Does not work to change SDDM cursor theme or size
    #     sessionCommands = ''
    #       # export XCURSOR_SIZE=64
    #       ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic/cursors/left_ptr 128 &disown
    #       ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
    #         Xft.dpi: ${toString config.hostParams.dekstop.dpi}
    #         Xcursor.theme: Bibata-Modern-Classic
    #         Xcursor.size: 64
    #       EOF
    #     '';
    #   };
    # };

    services.displayManager = {
      defaultSession = config.hostParams.desktop.defaultSession;
      sddm = {
        enable = true;
        extraPackages = with pkgs; [
          sddm-themes  # Must be installed globally, not home
          bibata-cursors
        ] ++ (if config.hostParams.desktop.sddmThemeQt6 then [ sddm-astronaut ] else []);
        enableHidpi = true;
        wayland.enable = true;
        settings = {
          # Wayland.SessionDir = "${pkgs.hyprland}/share/wayland-sessions";
          Theme = {
            CursorSize = 28;

            Current = config.hostParams.desktop.sddmTheme;

            ## Does not work to change SDDM cursor theme
            ## see profile/desktop.nix for how this is changed
            # CursorTheme = "bibata-cursors";
          };
          General = {
            GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=${toString config.hostParams.desktop.dpi}";
          };
        };
      } // (if config.hostParams.desktop.sddmThemeQt6 then {
        ## Have to mkForce in case plasma6 is managing it as well.
        package = lib.mkForce pkgs.kdePackages.sddm;
      } else {});

      autoLogin = {
        enable = config.hostParams.desktop.autoLogin;
        user = userParams.username;
      };
    };

    services.getty = {
      autologinUser = null;
      helpLine = lib.mkForce "";
    };

    systemd.services."getty@tty1".enable = false;

    environment.systemPackages = with pkgs; [ sddm-astronaut ];

    # To prevent getting stuck at shutdown
    systemd.extraConfig = "DefaultTimeoutStopSec=10s";

    ## Does not work to change SDDM cursor size
    # systemd.services.display-manager = {
    #   serviceConfig = {
    #     Environment = "XCURSOR_SIZE=64";
    #   };
    # };

    #---------------------------------------------------------------------------
    # As a systemd service
    #---------------------------------------------------------------------------

    # environment.etc."sddm.conf".text = ''
    #   [General]
    #   DefaultSession=sway.desktop
    #   DisplayServer=wayland
    #   HaltCommand=/run/current-system/systemd/bin/systemctl poweroff
    #   Numlock=none
    #   RebootCommand=/run/current-system/systemd/bin/systemctl reboot

    #   [Theme]
    #   Current=adapta
    #   FacesDir=${pkgs.sddm}/share/sddm/faces
    #   ThemeDir=${sddm-themes}/share/sddm/themes

    #   [Users]
    #   HideShells=/run/current-system/sw/bin/nologin
    #   HideUsers=nixbld1,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld2,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld3,nixbld30,nixbld31,nixbld32,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9
    #   MaximumUid=30000

    #   [Wayland]
    #   CompositorCommand=${pkgs.sway}/bin/sway
    #   # CompositorCommand=${pkgs.weston}/bin/weston --shell=fullscreen-shell.so
    #   EnableHiDPI=true
    #   SessionCommand=${pkgs.sddm}/share/sddm/scripts/wayland-session
    #   SessionDir=${config.services.xserver.displayManager.sessionData.desktops}/share/wayland-sessions
    # '';

    # systemd.services.sddm = {
    #   description = "Simple Desktop Display Manager";
    #   documentation = [ "man:sddm(1) man:sddm.conf(5)" ];
    #   conflicts = [ "getty@tty1.service" ];
    #   # wantedBy = [ "display-manager.service" ];
    #   after = [
    #     "systemd-user-sessions.service"
    #     "getty@tty1.service"
    #     "plymouth-quit.service"
    #     ## plymouth-quit.service doesn't exist...
    #     # "plymouth-quit-wait.service"
    #     "systemd-logind.service"
    #   ];

    #   serviceConfig = {
    #     ExecStart = "${pkgs.sddm}/bin/sddm";
    #     Restart = "always";
    #   };
    # };

    # security.pam.services = {
    #   sddm = {
    #     allowNullPassword = true;
    #     startSession = true;
    #   };

    #   sddm-greeter.text = ''
    #     auth     required       pam_succeed_if.so audit quiet_success user = sddm
    #     auth     optional       pam_permit.so
    #     account  required       pam_succeed_if.so audit quiet_success user = sddm
    #     account  sufficient     pam_unix.so
    #     password required       pam_deny.so
    #     session  required       pam_succeed_if.so audit quiet_success user = sddm
    #     session  required       pam_env.so conffile=/etc/pam/environment readenv=0
    #     session  optional       ${config.systemd.package}/lib/security/pam_systemd.so
    #     session  optional       pam_keyinit.so force revoke
    #     session  optional       pam_permit.so
    #   '';

    #   sddm-autologin.text = ''
    #     auth     requisite pam_nologin.so
    #     auth     required  pam_succeed_if.so uid >= 1000 quiet
    #     auth     required  pam_permit.so
    #     account  include   sddm
    #     password include   sddm
    #     session  include   sddm
    #   '';
    # };

    # users.users.sddm = {
    #   createHome = true;
    #   home = "/var/lib/sddm";
    #   group = "sddm";
    #   uid = config.ids.uids.sddm;
    # };

    # users.groups.sddm.gid = config.ids.gids.sddm;

    # services.dbus.packages = [ pkgs.sddm ];
  };
}
