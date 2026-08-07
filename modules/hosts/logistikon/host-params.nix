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
      hostName = "logistikon";
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
      ## On so the 3D view survives a reboot. genai-server's kiosk is a USER
      ## service, so with a greeter on the console there is no session for it
      ## to run in and a rebooted box shows nothing until somebody logs in —
      ## which on a headless-most-of-the-time GPU box can be days. This is
      ## not an open desktop: dmsLockProgram is "dms", so the session locks
      ## itself the instant it starts (lockAtStartup, wired to this flag in
      ## nixcfg-niri), and what is on screen is the same lock as before. The
      ## difference is that a session now exists behind it, which is all the
      ## kiosk needed.
      autoLogin = true;
      wallpaper = ../../../wallpapers/hawaii-dylan-theo.jpg;
      waybarSimple = true;
      ## DMS's own lock, not hyprlock, and the reason is the 3D view: a
      ## Wayland session lock is exclusive, so a locked screen can only show
      ## something if the LOCKER shows it — and hyprlock cannot be opened by
      ## anything but a typed password (PAM only; no D-Bus unlock, checked in
      ## the binary). DMS's lock has `dms ipc call lock unlock`, which lets
      ## genai-server's kiosk let itself in while nobody is here and re-lock
      ## the moment anyone is. See services.genai-server.kiosk in
      ## configuration.nix.
      dmsLockProgram = "dms";

      ## ...and with nothing to look at behind that lock, turn the panel off
      ## rather than lighting an empty room for the five minutes DMS's own
      ## monitor timeout takes. This box boots to nobody: the session exists
      ## for the kiosk and the services, not for a person, and the kiosk
      ## wakes the screen itself (kiosk.wakeCommand) when there is finally
      ## something on it. Ten seconds because input inside the window cancels
      ## it — a reboot somebody is sitting through stays lit — and because it
      ## outlasts the output configuration and kanshi restart that a session
      ## start does anyway, either of which powers a monitor straight back on.
      blankAtStartupSeconds = 10;

      startupWorkspace = "ten";
      # No workspaceOutput: this host has no built-in panel to pin them to.

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
        # "spotify"
        # "brave"
        # "firefox"
        # "flatpak run com.valvesoftware.Steam -cef-force-gpu -no-cef-sandbox steam://open/bigpicture"
      ];
    };

    gpu = {
      nvidia.enable = true;
      amd.enable = true;
    };
  };
}
