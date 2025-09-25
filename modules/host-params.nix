{ lib, ... }:
{
  options.hostParams = {
    system = {
      hostName = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = "Hostname for the system";
      };

      ## @TODO: Detect or have user enter during setup
      timeZone = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "America/Los_Angeles";
        description = ''
          Timezone for the system in tz database format.
          See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

          example: Etc/UTC
        '';
      };

      uid = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "User ID of main user. Use 1026 to match UID of admin user on Synology NAS";
      };

      gid = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = "Group ID of main user.";
      };

      thinkpad-battery-charge-to-full = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Charge battery to full on thinkpads";
      };
    };

    networking = {
      ## @DEPRECATED: Not used anymore
      wireguardIp = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Wireguard IP";
      };
    };

    containers = {
      backend = lib.mkOption {
        type = lib.types.str;
        default = "podman";
        description = "Container backend";
      };
    };

    virtualisation = {
      virtualbox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install Virtualbox";
        };
      };

      vmware = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install VMware";
        };
      };

      waydroid = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install Waydroid";
        };

        width = lib.mkOption {
          type = lib.types.int;
          default = 1600;
          description = "Default width of Waydroid";
        };

        height = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "Default height of Waydroid";
        };
      };
    };

    desktop = {
      displayManager = lib.mkOption {
        type = lib.types.str;
        default = "sddm";
        # default = "lightdm";
        description = "Display manager";
      };

      sddmTheme = lib.mkOption {
        type = lib.types.str;
        default = "sddm-astronaut-theme";
        description = "SDDM Theme";
      };

      sddmThemeQt6 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether SDDM theme uses QT6";
      };

      defaultSession = lib.mkOption {
        type = lib.types.str;
        default = "hyprland";
        # default = "none";
        # default = "plasma";
        # default = "sway";
        # default = "none+i3";
        description = "Default desktop session";
      };

      multipleSessions = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable all available sessions";
      };

      useHyprlandFlake = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use the Hyprland repo flake directly";
      };

      swayTouchpadClickMethod = lib.mkOption {
        type = lib.types.str;
        default = "clickfinger";
        # default = "button_areas";
        description = "Sway touchpad click interaction config";
      };

      defaultLockProgram = lib.mkOption {
        type = lib.types.str;
        default = "hyprlock";
        # default = "swaylock";
        description = "Default screenlock program";
      };

      autoLogin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to log in automatically";
      };

      dpi = lib.mkOption {
        type = lib.types.int;
        default = 192;
        description = "Screen DPI";
      };

      disableXwaylandScaling = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable Xwayland scaling and use Xft.dpi instead";
      };

      ttyFontSize = lib.mkOption {
        type = lib.types.float;
        default = 9.0;
        description = "Default TTY font size";
      };

      ttyLineHeight = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Default TTY line height";
      };

      trolltechFontSize = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Default font size for trolltech Qt apps";
      };

      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to wallpaper";
      };

      waybarSimple = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Simplified Waybar config";
      };
    };

    programs = {
      defaultBrowser = lib.mkOption {
        type = lib.types.str;
        default = "firefox";
        # default = "chromium-browser";
        description = "Default web browser";
      };

      steam = {
        enableGamescope = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Steam Gamescope";
        };
      };
    };

    gpu = {
      amd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable AMD GPU support";
        };
      };

      intel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Intel GPU support";
        };

        disableModules = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Disable Intel GPU kernel modules";
        };
      };

      nvidia = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable NVidia GPU support";
        };
      };
    };
  };
}
