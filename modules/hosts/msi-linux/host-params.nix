{ ... }:
{
  hostParams = {
    networking = {
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
    };

    system = {
      hostName = "msi-linux";
    };

    containers = {
      backend = "docker";
    };

    desktop = {
      displayManager = "dms";
      # displayManager = "jovian";
      # defaultSession = "gamescope-wayland";
      defaultSession = "niri";
      multipleSessions = true;
      ttyFontSize = 9.5;
      dpi = 192;
      autoLogin = true;
      wallpaper = ../../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
      dmsLockProgram = "hyprlock";

      startupWorkspace = "ten";
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
        # "flatpak run com.valvesoftware.Steam -cef-force-gpu -no-cef-sandbox steam://open/bigpicture"
      ];
    };

    gpu = {
      nvidia.enable = true;
      intel.enable = true;
      intel.disableModules = false;
    };
  };
}
