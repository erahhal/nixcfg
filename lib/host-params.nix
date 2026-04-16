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

    user = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "erahhal";
        description = "Primary username";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Ellis Rahhal";
        description = "User's full name";
      };
      shell = lib.mkOption {
        type = lib.types.str;
        default = "zsh";
        description = "Default shell";
      };
      tty = lib.mkOption {
        type = lib.types.str;
        default = "foot";
        description = "Default terminal emulator";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Primary email address for this host (set in secrets)";
      };
      protonmailEmail = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "ProtonMail email address for protonmail-bridge (set in secrets)";
      };
    };

    networking = {
      networkMonitor = {
        normalEndpoint = lib.mkOption {
          type = lib.types.submodule {
            options = {
              endpoint = lib.mkOption {
                type = lib.types.str;
                default = "https://github.com";
              };
              method = lib.mkOption {
                type = lib.types.enum [ "http" "ping" ];
                default = "ping";
              };
            };
          };
          default = {};
          description = "Default (non-VPN) connectivity check endpoint and method.";
        };
        vpnEndpoints = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              endpoint = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
              method = lib.mkOption {
                type = lib.types.enum [ "http" "ping" ];
                default = "http";
              };
            };
          });
          default = {};
          description = "Per-VPN-interface endpoint config. Key = interface name (tailscale0, wg0, tun0, …).";
        };
      };

      tailscale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Tailscale VPN";
        };
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

      libvirtd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable libvirtd";
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
        # default = null;
        default = "niri";
        # default = "hyprland";
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


      defaultLockProgram = lib.mkOption {
        type = lib.types.str;
        default = "hyprlock";
        # default = "swaylock";
        description = "Default screenlock program";
      };

      dmsLockProgram = lib.mkOption {
        type = lib.types.enum [ "dms" "hyprlock" ];
        default = "dms";
        description = "Lock screen program to use with DMS (dms = built-in Quickshell lock, hyprlock = standalone)";
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

      location = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "City/region display string (used by widgets: weather, news, events, etc.).";
      };

      coordinates = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Latitude, longitude (used by widgets needing GPS: weather, local services, etc.).";
      };

      useFahrenheit = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use Fahrenheit instead of Celsius wherever temperature is displayed.";
      };

      killOnExit = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Process names to pkill before session exit/reboot/poweroff, for a clean logout.";
      };

      cycleColumnsOnRepeatedWorkspaceFocus = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "When pressing Mod+<N> while already on workspace N, cycle through columns instead of doing nothing.";
      };

      waybarSimple = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Simplified Waybar config";
      };

      gamescope = {
        halveResolution = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Halve gamescope inner resolution when display exceeds max dimensions";
        };

        maxWidth = lib.mkOption {
          type = lib.types.int;
          default = 2880;
          description = "Maximum display width before resolution is halved";
        };

        maxHeight = lib.mkOption {
          type = lib.types.int;
          default = 1800;
          description = "Maximum display height before resolution is halved";
        };
      };
    };

    programs = {
      defaultBrowser = lib.mkOption {
        type = lib.types.str;
        default = "firefox";
        # default = "chromium-browser";
        description = "Default web browser";
      };

      startupApps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Applications to launch at startup via the startup-apps systemd service";
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

        defaultWindowManagerGpu = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Make default GPU even if nvidia is enabled";
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
