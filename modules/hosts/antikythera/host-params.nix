{ ... }:
{
  hostParams = {
    networking = {
      tailscale.enable = true;
      networkMonitor = {
        vpnEndpoints = {
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
      # Disabled: recent kernels appear to have resolved the ath11k boot/resume
      # issue. Re-enable if WiFi fails to come up at boot or after suspend.
      wifi.ath11kRestartFix.enable = true;
    };

    system = {
      hostName = "antikythera";
      uid = 1000;
      gid = 100;
      # timeZone = "America/Denver";
      thinkpad-battery-charge-to-full = false;
    };

    desktop = {
      displayManager = "dms";
      multipleSessions = true;
      defaultSession = "niri";
      dpi = 192;
      wallpaper = ../../../wallpapers/huashan-temple.jpg;
      disableXwaylandScaling = true;
      dmsLockProgram = "hyprlock";

      # On-demand Persona-Quickshell: `persona` runs the full shell; Mod+D
      # switches between DMS and Persona, Mod+P opens the active shell's
      # launcher. DMS stays the session shell until you switch.
      persona.enable = true;

      location = "Los Angeles, CA";
      coordinates = "34.1509, 118.4487";
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

    cpu = {
      amd.ryzenadj = "off";   # options: off, medium, high
    };

    gpu = {
      amd.enable = true;
      ## VRAM-management boost via dmem cgroup controller. Requires the
      ## CachyOS kernel; see modules/hardware/dmemcg.
      amd.dmemcg.enable = false;  # Currently false, seeing AMD HW video decoder crashes, might be related
    };
  };
}
