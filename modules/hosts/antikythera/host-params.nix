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
          tun0 = {
            endpoint = "google.com";
            method = "ping";
          };
        };
      };
      # Re-enabled 2026-07-21: at boot iwd can race ath11k's asynchronous
      # regulatory-domain attach (nl80211 GET_REG WARN -> -EINVAL) and then
      # permanently abandon the device, leaving wlan0 "unavailable" until
      # the module is reloaded. The hooks this enables (see "WiFi recovery"
      # in configuration.nix) are conditional -- they reload only when the
      # device is actually broken -- and the boot service has
      # RemainAfterExit, so rebuild switches no longer restart NM or desync
      # the DMS wifi icon (the failure mode of the retired ath11k-boot-fix).
      wifi.ath11kRestartFix.enable = true;
    };

    system = {
      hostName = "antikythera";
      uid = 1000;
      gid = 100;
      # timeZone = "America/Denver";
      # timeZone = "Asia/Shanghai";
      # timeZone = "Asia/Tokyo";
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

      startupWorkspace = "five";
      # Keep the named workspaces on the laptop panel regardless of what's docked.
      workspaceOutput = "eDP-1";

      # Mod+G cycles the ThinkVision between this machine and whatever is on
      # its other input.
      ddcInputToggle = {
        enable = true;
        title = "Switch ThinkVision Monitor Input";
        monitor = "P40w-20";
        inputs = [
          { code = "0x0f"; label = "DisplayPort-1"; }
          { code = "0x31"; label = "HDMI-2"; }
        ];
      };

      # Hand the lid to logind so it can suspend-then-hibernate (see
      # systemd.sleep.settings.Sleep in configuration.nix). This also unbinds
      # niri's lid-close handler -- with both armed, the compositor's suspend
      # request was frozen at lid close and replayed on resume, putting the
      # machine back to sleep right after the lock screen appeared.
      # hypridle's before_sleep_cmd still locks with hyprlock on the way down.
      lidCloseAction = "suspend-then-hibernate";

      # On-demand Persona-Quickshell: `persona` runs the full shell; Mod+D
      # switches between DMS and Persona, Mod+P opens the active shell's
      # launcher. DMS stays the session shell until you switch.
      persona.enable = true;

      # On-demand hypr-comp shell (vendored + being ported to niri). Stage 0:
      # installs the `hypr-comp` command for foreground testing; no autostart.
      hyprComp.enable = true;

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
