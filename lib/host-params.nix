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

      lidCloseAction = lib.mkOption {
        type = lib.types.enum [
          "compositor" "ignore" "lock" "suspend" "hibernate" "hybrid-sleep"
          "suspend-then-hibernate" "poweroff"
        ];
        default = "compositor";
        description = ''
          Who handles lid close under niri. "compositor" (default) leaves
          logind's HandleLidSwitch at "ignore" and lets niri's lid-close
          binding lock + suspend; any other value is passed to logind's
          HandleLidSwitch and drops the niri binding.

          Set this instead of overriding services.logind.lidSwitch directly —
          forcing that option leaves both handlers armed, and the compositor's
          suspend request gets frozen mid-flight and replayed on the next
          resume, immediately re-suspending the machine.

          "suspend-then-hibernate" also needs systemd.sleep.settings.Sleep
          (HibernateDelaySec / HibernateOnACPower) set on the host. On
          NVIDIA hosts leave HibernateOnACPower at its default; see
          modules/hardware/gfx-nvidia.

          Mirrors to nixcfg-niri.desktop.lidCloseAction via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      startupWorkspace = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Named workspace the session lands on at login (one .. ten). null
          leaves niri on its first workspace.

          Mirrors to nixcfg-niri.desktop.startupWorkspace via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      workspaceOutput = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Output the ten named workspaces are pinned to (connector name or
          make/model/serial). Keeps the named workspaces on the built-in panel
          of a laptop that docks to varying monitors. null lets niri place them
          on whatever output is active.

          Mirrors to nixcfg-niri.desktop.workspaceOutput via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      blankAtStartupSeconds = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = ''
          Power the monitors off this many seconds into a session nobody has
          touched yet. null (default) leaves the screen lit until the shell's
          normal monitor timeout.

          For an autologin host that comes up locked: the session is already
          behind a lock screen, so there is nothing to look at until somebody
          arrives, and any input brings the screen back. Input inside the
          window cancels it, so a boot you sat through does not go dark.

          Mirrors to nixcfg-niri.desktop.blankAtStartupSeconds via
          modules/desktop/niri/user-overrides.nix.
        '';
      };

      ddcInputToggle = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        example = lib.literalExpression ''
          {
            enable = true;
            monitor = "P40w-20";
            inputs = [
              { code = "0x0f"; label = "DisplayPort-1"; }
              { code = "0x31"; label = "HDMI-2"; }
            ];
          }
        '';
        description = ''
          Keybind that cycles an external monitor through its inputs over
          DDC/CI, for a display shared with another machine. Needs the monitor
          identifier and its VCP 0x60 input codes — see `ddcutil detect` and
          `ddcutil getvcp 60`. Requires modules/desktop/i2c.

          Passed through to nixcfg-niri.desktop.ddcInputToggle (which types the
          attributes) via modules/desktop/niri/user-overrides.nix.
        '';
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

      greyline.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Install greyline, a live world-time desktop wallpaper (a modern
          recreation of the ThinkPad "World Time" Active Desktop). Renders a
          world map with clocks + a day/night terminator once per minute and
          paints it via its own swww daemon.

          Note: DankMaterialShell also manages the wallpaper. To actually see
          greyline, disable the DMS wallpaper on the host (e.g. set
          hostParams.desktop.wallpaper = null); otherwise the two background
          layers conflict.

          Mirrors to nixcfg-niri.desktop.greyline.enable via
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

      autoFocusUrgentWindows = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Focus any window that raises an urgency hint (xdg-activation), which
          also switches to that window's workspace. True is the long-standing
          behaviour: clicking a link in chat follows the browser to whichever
          workspace it opened the tab on.

          Set false on hosts that drive a GUI automatically. Browser automation
          over CDP raises windows through this same mechanism, so with it on the
          session gets dragged between workspaces for the length of the job.
          Turning it off keeps the signal -- the hint stays set, so DMS's
          workspace indicator lights that workspace in its urgent colour and
          niri draws the window's border in urgent-color.

          Mirrors to nixcfg-niri.desktop.autoFocusUrgentWindows via
          modules/desktop/niri/user-overrides.nix.
        '';
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

      mediaserverSender = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Send this machine's audio to the house speakers: a "House
            speakers" output whose audio becomes this machine's own stream on
            the HomeFree box's snapserver. Nothing about this machine is
            configured on the server. See modules/services/mediaserver-sender.
          '';
        };

        serverHost = lib.mkOption {
          type = lib.types.str;
          default = "homefree";
          description = "The snapserver's host name; used only when serverAddress is null.";
        };

        serverAddress = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "10.0.0.1";
          description = "The server's IPv4 address: the sender connects to it, and the firewall lets it in to pull the audio. null connects to serverHost and leaves the firewall alone.";
        };
      };
    };

    programs = {
      startupApps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Applications to launch at startup via the startup-apps systemd service";
      };

      xteink-unlocker.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Xteink Unlocker: flashes CrossPoint Reader onto USB-locked Xteink
          e-readers by intercepting their OTA update check. Installs the GUI plus
          a privileged helper unit that is deliberately never started at boot --
          it turns the Wi-Fi radio into a hotspot and spoofs DNS/NTP while up, so
          it is started by hand for the duration of a flash. See
          modules/programs/xteink-unlocker.
        '';
      };

      nerd-dictation.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          nerd-dictation: offline streaming speech-to-text (Vosk), toggled
          from a niri hotkey. Its pre-warmed user daemon keeps the model
          resident even while idle -- ~5 GB for the full en-us-0_22 model.
          See modules/programs/nerd-dictation.
        '';
      };
    };

    services = {
      nfs-mounts.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          NFS automount of 10.0.0.1:/mnt/data at /mnt/data, plus a policy
          route that sends 10.0.0.0/24 out the LAN interface (around any VPN)
          while on the home network. See modules/services/nfs-mounts.
        '';
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
              Enable dmem cgroup VRAM-management boost (dmemcg-booster +
              foreground booster). Needs a kernel carrying pixelcluster's
              dmem cgroup patches, which mainline did not as of 2026-05 and
              nothing here provides any more. Useful on hosts with
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

    aiCoding = {
      localModel = lib.mkOption {
        type = lib.types.str;
        default = "qwen38-125b-a6b-q5";
        example = "qwen38-27b-224k";
        description = ''
          The model every `*-local` harness reaches for when none is given:
          claude-local, opencode-local and hermes-local alike.

          ONE OPTION FOR ALL OF THEM, and that is the point. It was
          `claudeModel` and it moved only Claude Code, so the fleet's answer
          to "which model do I code against" lived in three places and drifted
          — opencode sat on `qwen3-coder-80b-a3b` for a month after claude-local moved
          off it, which is not an A/B when nobody is reading the result, just
          two harnesses disagreeing. Change it here and every local harness
          moves together.

          For Claude Code it sets the main, sonnet/opus and SUBAGENT slots
          at once — picking a model with `/model` inside a session moves only
          the main one, leaving the others behind, and two large models
          alternating is what makes llama-swap thrash.

          Defaulted here rather than per host: every host runs the same
          wrappers against the same server, so a model chosen on one of them
          is chosen for all of them. It lived in logistikon's
          configuration.nix until 2026-08-04, which meant the laptops kept
          quietly getting the old value while the box that needed the setting
          least was the only one with it.

          `qwen38-125b-a6b-q5` SINCE 2026-10-19: Qwen3.8-Flash-Next, the
          125B-A6B MoE, at UD-Q5_K_XL and 262144, on Strata. The family has
          held this option since 2026-08-28 on its AGENTIC margins, which is
          the axis a `*-local` harness actually runs on: on Qwen's own
          head-to-head against the 27B dense, DeepSWE 1.1 58.7 against 42.2,
          JobBench 55.7 against 33.4, Toolathlon 73.5 against 67.1, Agents'
          Last Exam 51.2 against 42.9. Single-shot coding is nearly a tie
          (SWE-bench Pro 62.5 against 61.7), so this is a bet on long
          tool-driven sessions and not on one-shot answers.

          Q5 OVER `-max`'S Q4 because Strata erased the speed gap that kept
          it off: with the image encoder loaded both write at 55-65 tok/s
          (Q5 55-63), and Q5 is 93.7% top-1 against the full weights where
          Q4 is 92.3% (unsloth's numbers; KLD falls 35%). On llama.cpp Q5
          was the slow rung — 25 tok/s, 333 tok/s prefill — which is why
          `-max` held this until Strata.

          WHAT IT COSTS. ~71GB of host RAM pinned while it is loaded, against
          -max's ~49GB, and slower READING: 1.1-1.4k tok/s at ~4k tokens and
          2.5k at 37k, where -max reads 1.7-4.5k. Strata keeps each
          conversation's state in RAM between turns, so that is mostly the
          price of a cold start or a compaction rather than of every turn.

          IT IS A STRATA CHOICE. With genai-server's `strata.enable` off the
          same name runs on llama.cpp at the numbers above, and the right
          value goes back to `qwen38-125b-a6b-max`. Nothing here can check
          that — whether a host runs Strata is the serving host's config,
          not this module's.

          `qwen38-125b-a6b-max` is the same weights at Q4 and the same
          speed, ~20GB lighter in RAM. `qwen38-125b-a6b` is the fast tier,
          IQ3_XXS at 157-195 tok/s, for sessions where turnaround matters
          more than the last points of fidelity. `qwen38-27b-128k` is the
          dense 27B, which held this before the 125B arrived.

          Windows are read from the catalog rather than assumed, so
          auto-compaction and opencode's `limit.context` move with this
          automatically — nothing here needs to know a number.

          A NAME THE SERVER DOES NOT SERVE FAILS AT THE BRIDGE, NOT HERE: the
          list comes from the genai-server input, so bump that input with any
          change to this, or the harnesses ask for a name nothing serves.
        '';
      };
      agentReserve = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 65536;
        example = 0;
        description = ''
          Tokens of the model's window that claude-local holds back from the
          CONVERSATION, so a background subagent has somewhere to run.

          THE WINDOW IS NOT THE CONVERSATION'S BUDGET. llama-server is
          started with `-np` unset, so it takes four slots, and on b10472
          those slots share ONE KV pool the size of the window — they do not
          get a window each. Everything live at once spends the same pool.

          claude-local otherwise tells Claude Code the whole window is
          available, which entitles the main loop to consume all of it and
          leaves a background `Agent` with nothing. The failure is
          llama.cpp's "Context size has been exceeded.", on BOTH streams,
          after each re-prefills its whole prompt — about a minute per
          attempt, and retrying does not help. Measured 2026-08-18: a
          63,761-token conversation plus a 32,730-token background subagent
          exhausted a 131072 window. LiteLLM cannot catch it either, because
          it arrives as a 500 and `context_window_fallbacks` never fires.

          So the DECLARED window is the served window minus this, and the
          difference is pool nothing will compact into. 65536 is two
          subagents at the size that incident measured. Zero disables it,
          which is right only for a session that will not delegate.

          claude-local only. opencode-local and hermes-local take the served
          window whole.
        '';
      };
      claudeCompactAt = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 143360;
        example = 0;
        description = ''
          A CEILING on the context size at which claude-local has Claude Code
          auto-compact. 0 disables the clamp and restores the derived value,
          which is the declared window minus one output budget.

          COMPACTION IS THE HARDEST CALL A SESSION MAKES AND IT IS MADE AT THE
          WORST MOMENT. It sends the whole conversation and asks for a
          summary, so the prompt is the largest the session ever sends, the
          task is the hardest, and generation is at its slowest — while the
          output budget is the same 16384 a one-line answer gets, shared
          between the thinking trace and the summary itself. When the trace
          spends all of it the model returns EMPTY content, Claude Code has
          nothing to compact with, and the session is over: "automatic
          compaction failed: summarization produced empty response",
          recoverable only by /clear. It is the same failure the `medium`
          reasoning-effort default in genai-server's module.nix exists to
          bound, arriving on the one call where empty output is fatal.

          THE NUMBER IS MEASURED, from claude-local transcripts on
          qwen38-125b-a6b-max: compaction succeeded at 133,676 tokens of
          context (19,456-char summary) and at 150,184 (15,270 chars), and
          FAILED at ~180,224 — which is exactly what the derived value
          produces on a 262144 window at the default agentReserve.

          IT IS NOT SET AT THE LAST VALUE THAT WORKED, and the two successes
          are why: 12% more conversation produced 21% LESS summary. Above
          ~133k the budget is already squeezed and compaction starts
          succeeding while carrying less forward — quieter than the crash,
          because nothing reports it and the model merely seems to have
          forgotten more than it should have. 143360 (140 x 1024) sits
          between the two confirmed successes, nearer the one with room.

          Derived from the same CTX as the other window numbers, so a host on
          a narrower model keeps the derived value untouched whenever it is
          already below this.
        '';
      };
      claudeBackgroundModel = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "fast-cpu";
        description = ''
          Model id claude-logistikon points its BACKGROUND slot at — the one
          Claude Code uses for conversation titles and small classification
          calls. Empty (the default) pins it to the session's main model,
          which is the historical behaviour.

          Only safe to change to a model that costs NO VRAM. Two GPU models
          resident at once is what "upstream command exited prematurely"
          means on a 32GB card, and background traffic runs concurrently
          with the conversation. genai-server's `fast-cpu` is the intended
          value: the same 4B weights as `voice`, on the CPU, with tool calls.

          Subagents are deliberately unaffected — they do real work, and a 4B
          is the wrong place to send it.

          IT DOES NOT MOVE THE AUTO-MODE CLASSIFIER, which is the other
          "small classification call" and the one that costs a session. That
          runs on the SONNET slot and falls back to the main model — see
          `claudeAutoModeModels`. Two questions that name similar-looking
          slots; do not merge them.
        '';
      };
      claudeAutoModeModels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "qwen38-125b-a6b-q5" ];
        example = [ "qwen38-125b-a6b-q5" "qwen38-27b-128k" ];
        description = ''
          The models claude-local leaves AUTO MODE available on. Anything not
          named here starts with `permissions.disableAutoMode = "disable"`,
          which takes auto out of the shift-tab carousel and refuses
          `--permission-mode auto` rather than half-working.

          WHAT AUTO MODE COSTS, measured against a mock endpoint on
          2026-09-10 rather than guessed: every non-read-only Bash command
          triggers a second, separate inference before the command runs — a
          "security monitor" classifier carrying a 110,180-character
          (~27.6k token) system prompt, non-streaming, `max_tokens` 2112,
          and the whole call is cut off at 60 SECONDS. The prompt is marked
          `cache_control: ephemeral`, which is the tell: the feature is
          designed around Anthropic's prompt cache, where re-sending 27.6k
          tokens is a cache read costing milliseconds.

          llama.cpp has no such cache — it can only reuse a prefix a slot
          still holds. So the deadline is met or missed on whether that
          27.6k prefix survived the conversation's own turns, which is luck.
          On `qwen38-125b-a6b-max` (436 tok/s prefill on llama.cpp) a cold
          re-prefill is ~63s and loses the race by a few seconds; measured
          in a real session, five denials landed at exactly 60.0s after the
          tool call. It then FAILS CLOSED and denies the command, saying the
          model is "temporarily unavailable" — which reads as transient, so
          the agent retries with sleeps that cannot help, because nothing is
          recovering. The box is fine throughout: LiteLLM logged 200 for
          every one of those requests.

          So this is an allow list: off is the state that works, and a model
          earns its way on by MEASUREMENT — prefill fast enough to absorb the
          prompt with time left to answer. Being listed makes auto AVAILABLE
          (shift-tab, `--permission-mode auto`); `claudePermissionMode` is
          still what a session starts in.

          `qwen38-125b-a6b-q5` EARNED IT ON STRATA, measured 2026-10-19 by
          capturing claude-code 2.1.289's real classifier request against a
          stub and replaying it through the controller's bridge. The prompt
          has grown — 139,634 characters, 30,646 tokens as the server counts
          them — and is two-stage now by its own wording (stage 1 blocks
          broadly and leaves the exceptions to a stage 2). Cold: 21.1s. Repeated: 6.3s, with 30,641 of those
          tokens served from Strata's conversation cache, and still 6.5s
          after an unrelated 21k-token turn in between, because Strata parks
          that prefix in RAM instead of evicting it. Every answer came back
          in the required `<block>` form after 400-530 tokens of thinking.

          THE ONE WAY IT CAN STILL LOSE: Strata answers one request at a
          time, so a check that arrives while a BACKGROUND agent is mid-reply
          waits for that reply first, and a long one can push it past 60s.
          The denial looks exactly like the llama.cpp one above. A session
          leaning on background agents is the case for leaving auto off.

          The other 125B entries are unmeasured and stay off: `-max` and the
          IQ3_XXS tier read faster than Q5 on Strata and would likely pass,
          but this list is for measured. On llama.cpp none of them did.
          `qwen38-27b-128k` (489-729 tok/s) is the plausible llama.cpp one.

          `CLAUDE_CODE_AUTO_MODE_MODEL` looks like the knob for this and is
          ignored in claude-code 2.1.223 — tested with both an id and an
          alias, the classifier still went to the sonnet slot.
        '';
      };
      claudePermissionMode = lib.mkOption {
        type = lib.types.str;
        default = "acceptEdits";
        example = "default";
        description = ''
          What claude-local starts a session in — `permissions.defaultMode`.
          Empty leaves it to Claude Code (which remembers per project).

          `acceptEdits` because the alternative to auto mode should not be a
          prompt on every file write; Bash still asks, and an allow rule in
          `~/.claude-local/settings.json` is how a command stops asking.

          It arrives via `--settings`, which outranks `settings.json` — so
          this is the place to change it, and editing the mode in the UI
          will not survive the next session.
        '';
      };

      ## WHERE THE FLEET IS ANSWERED FROM, which is not where the card is.
      ##
      ## These used to be one hardcoded `logistikon.lan`, from when the box
      ## WAS the deployment. It is now a node behind a control plane, and
      ## the two halves the harnesses need — the Anthropic-protocol bridge
      ## and the MCP gateway — are both controller-scoped. Pointing at a
      ## node got away with it for the models (genai-server ran a LiteLLM on
      ## every machine until 2026-08-18) and silently did not for the tools:
      ## no node has ever listened on the gateway's port.
      controllerHost = lib.mkOption {
        type = lib.types.str;
        default = "10.0.0.1";
        example = "controller.lan";
        description = ''
          The machine running genai-server's controller half — the bridge,
          the MCP gateway, the tool servers. Every harness here points at
          it; nothing points at a node any more.

          AN ADDRESS RATHER THAN A NAME, deliberately, and the reason is a
          real outage. `logistikon.lan` resolved only through the router's
          DNS and only to that box's *wlan0* address, so one failure took
          out both the lookup and the route — and a VPN does exactly that
          (Mullvad with default "block local network sharing" strands every
          harness, 2026-07-31). An address removes the resolver from the
          path; it cannot remove the route, and that exposure is real and
          inherent now that the bridge is on another machine. The old
          arrangement answered it with loopback, which is no longer
          available: a node runs no bridge to loop back to.

          Also why it is not a `.lan` name: Tailscale's resolver expands
          search domains, which has resolved v4-only hosts here to the
          router's WAN address before.
        '';
      };

      controllerLitellmPort = lib.mkOption {
        type = lib.types.port;
        default = 9027;
        example = 4000;
        description = ''
          Port the controller's LiteLLM answers on.

          NOT genai-server's own 4000. HomeFree's app platform allocates
          ports for the stack it hosts — its portal is 9023 where the
          stack's default is 8897 — so this is that platform's number, and
          it is a value copied across a repo boundary with nothing checking
          it. Set it to 4000 for a controller that is a plain NixOS host
          running the module directly.

          The MCP gateway is not here because it is not remapped: the
          platform publishes it on the stack's own 8899.
        '';
      };
    };
  };
}
