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
        description = "User ID of main user.";
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

      nflxHost = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          This host pulls its AI coding harnesses from nflx-nixcfg
          (opencode/pi/hermes/claude wired to the Netflix gateway). When true,
          nixcfg's own opencode + OpenRouter wiring (modules/programs/ai-coding)
          is skipped to avoid duplicate installs.
        '';
      };

      openrouter = {
        apiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Path to a file containing the OpenRouter API key, read at runtime by
            the claude-openrouter / opencode-openrouter wrappers (never embedded
            in the nix store). Optional override: if left null, the ai-coding
            module auto-detects the shared agenix secret "openrouter-api-key"
            (config.age.secrets."openrouter-api-key".path) when it's declared.
          '';
        };

        model = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Default OpenRouter model id for claude-openrouter (exported as
            ANTHROPIC_MODEL), e.g. "anthropic/claude-sonnet-4.5". opencode picks
            the model in-app. Leave null to use the tool default.
          '';
        };
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

      wifi = {
        ath11kRestartFix = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Reload the ath11k_pci driver at boot and after resume to work
              around WiFi failing to come up on QCNFA765 / WCN6855 adapters.
              Only needed on older kernels where the ath11k driver is unstable
              after suspend/resume or boot.
            '';
          };
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

      easyeffects.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable EasyEffects: daemon autostart, DMS shell plugin, and preset
          install. Set to false on hosts where EasyEffects' virtual input
          source intercepts Bluetooth headset recording streams and breaks
          WirePlumber's A2DP->HSP autoswitch.

          Mirrors to nixcfg-niri.desktop.easyeffects.enable via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      persona.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Install Persona-Quickshell (a Persona 3 Reload-styled Quickshell
          shell) for on-demand use: adds the `persona` command plus niri
          keybinds — Mod+D switches between DMS and Persona (only one shell
          runs at a time), and Mod+P opens whichever shell's launcher is active.
          DankMaterialShell stays the session shell until you switch — nothing
          is autostarted.

          Mirrors to nixcfg-niri.desktop.persona.enable via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      hyprComp.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Install the ilyamiro "hypr-comp" Quickshell shell (vendored + ported
          toward niri) as a third on-demand session shell: adds the `hypr-comp`
          command. DankMaterialShell stays the session shell — nothing is
          autostarted. Several subsystems are degraded/disabled under niri.

          Mirrors to nixcfg-niri.desktop.hyprComp.enable via
          modules/desktop/niri/user-overrides.nix.
        '';
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
      startupApps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Applications to launch at startup via the startup-apps systemd service";
      };
    };

    cpu = {
      amd = {
        ryzenadj = lib.mkOption {
          type = lib.types.enum [ "off" "medium" "high" ];
          default = "off";
          description = "AMD CPU power tuning via ryzenadj: off=BIOS defaults, medium=balanced, high=max performance";
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

        dmemcg = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Enable dmem cgroup VRAM-management boost (CachyOS kernel +
              dmemcg-booster + foreground booster). Useful on hosts with
              low-VRAM AMD GPUs to keep the focused app's VRAM resident
              instead of being evicted to GTT by background apps.
              See: https://pixelcluster.github.io/VRAM-Mgmt-fixed/
            '';
          };

          foregroundBooster = lib.mkOption {
            type = lib.types.enum [ "niri" "none" ];
            default = "niri";
            description = ''
              Foreground-window tracker that promotes the focused app's
              cgroup. "niri" runs niri-focused-booster; "none" only
              activates the dmem controller (gamescope-launched games
              still benefit since gamescope sets the boost itself).
            '';
          };
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
