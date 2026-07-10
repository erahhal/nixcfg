{ ... }:
{
  hostParams = {
    # AI coding harnesses come from nflx-nixcfg on this host; skip nixcfg's own
    # opencode + OpenRouter wiring (modules/programs/ai-coding).
    user.nflxHost = true;

    system = {
      hostName = "nflx-erahhal-p16";
      uid = 1026;
      gid = 100;
      # timeZone = "America/Denver";
      thinkpad-battery-charge-to-full = false;
    };

    networking = {
      tailscale.enable = true;
      networkMonitor = {
        vpnEndpoints = {
          tun0 = {
            # endpoint = "https://data.netflix.net";
            # method = "http";
            endpoint = "data.netflix.net";
            method = "ping";
          };
          tailscale0 = {
            endpoint = "10.0.0.1";
            method = "ping";
          };
          wg0 = {
            endpoint = "github.com";
            method = "ping";
          };
        };
      };
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      # displayManager = "sddm";
      # sddmTheme = "nflx";
      # sddmThemeQt6 = false;

      displayManager = "dms";

      multipleSessions = true;
      defaultSession = "niri";
      useHyprlandFlake = false;
      disableXwaylandScaling = true;
      defaultLockProgram = "hyprlock";
      # dmsLockProgram = "hyprlock";
      autoLogin = false;

      # EasyEffects intercepts Bluetooth headset recording on this host,
      # breaking the A2DP->HSP autoswitch for the Bose NC 700 mic. Skip it.
      easyeffects.enable = false;

      # On-demand Persona-Quickshell: `persona` runs the full shell; Mod+D
      # switches between DMS and Persona, Mod+P opens the active shell's
      # launcher. DMS stays the session shell until you switch.
      persona.enable = true;

      # On-demand hypr-comp shell (vendored + being ported to niri). Stage 0:
      # installs the `hypr-comp` command for foreground testing; no autostart.
      hyprComp.enable = true;

      ttyFontSize = 9.0;
      ttyLineHeight = 10;
      dpi = 210;

      wallpaper = ../../../wallpapers/tokyo-park.jpeg;

      location = "Los Angeles, CA";
      coordinates = "34.1509, -118.4487";
      useFahrenheit = true;

      killOnExit = [
        "chromium" "chrome"
        "slack" "Slack"
        "brave" "Brave"
        "joplin" "joplin-desktop"
        "code"
        "spotify" "Spotify"
        "firefox"
        "signal" "signal-desktop" "Signal"
        "telegram" "telegram-desktop" "Telegram"
        "discord" "Discord"
        "vesktop"
        "app.asar"
        "element" "element-desktop" "Element"
        "electron"
        "whatsapp-for-linux"
        "vlc"
      ];
    };

    programs = {
      # foot is launched directly from niri spawn-at-startup (see niri.nix)
      # because systemd user services cannot use setuid binaries like sudo
      startupApps = [
        "chromium"
        "slack"
        "spotify"
        "brave"
        "firefox"
        "signal-desktop"
        "Telegram"
        "vesktop"
        "element-desktop"
        "joplin-desktop"
      ];
    };

    gpu = {
      nvidia.enable = true;
      ## If the intel GPU is disabled, you should also set the GPU to "discrete" in the BIOS.
      ## Otherwise the laptop display is still routed through the intel GPU, and generally doesn't work, either DPMS or rendering
      intel.enable = true;
      intel.disableModules = false;
      intel.defaultWindowManagerGpu = true;
    };

    virtualisation = {
      ## @BROKEN
      virtualbox.enable = false;
      ## @BROKEN
      vmware.enable = false;
      libvirtd.enable = true;
    };
  };
}
