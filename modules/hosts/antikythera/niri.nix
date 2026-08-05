{ config, lib, ... }:
let
  userParams = config.hostParams.user;

  greeter-compositor-config = lib.mkAfter ''
    // Internal laptop display on the left
    // ThinkVision logical: 3843x1621, Laptop logical: 1600x1000
    // Bottom-align: y = 1621 - 1125 = 496
    output "eDP-1" {
      mode "2880x1800@120"
      scale 1.8
      position x=0 y=800
      variable-refresh-rate
    }

    // ThinkVision on the right
    output "Lenovo Group Limited P40w-20 V90DFGMV" {
      mode "5120x2160@60.000"
      scale 1.333333
      position x=1600 y=0
      focus-at-startup
      variable-refresh-rate
    }
  '';
in
{
  # Set both option paths so the config applies whether the greeter is
  # sourced from the DMS flake (programs.dank-material-shell.greeter) or
  # from the nixpkgs-native module (services.displayManager.dms-greeter).
  # Only one is active at a time; the unused one is a no-op.
  programs.dank-material-shell.greeter.compositor.customConfig = greeter-compositor-config;
  services.displayManager.dms-greeter.compositor.customConfig = greeter-compositor-config;

  home-manager.users.${userParams.username} = {
    programs.niri.settings = {
      debug = {
        render-drm-device = "/dev/dri/by-path/pci-0000:c4:00.0-render";
      };

      outputs = {
        "eDP-1" = {
          mode = { width = 2880; height = 1800; refresh = 120.0; };
          scale = 1.8;
          variable-refresh-rate = true;
        };
        "Lenovo Group Limited P40w-20 V90DFGMV" = {
          mode = { width = 5120; height = 2160; refresh = 60.0; };
          scale = 1.333333;
          variable-refresh-rate = true;
        };
        "LG Electronics 16MQ70 20NKZ005285" = {
          mode = { width = 2560; height = 1600; refresh = 60.0; };
          scale = 1.6;
          variable-refresh-rate = true;
        };
        "LG Electronics LG Ultra HD 0x00043EAD" = {
          mode = { width = 3840; height = 2160; refresh = 60.0; };
          scale = 1.5;
          variable-refresh-rate = true;
        };
        "LG Electronics L33HD334K 0x00020F5B" = {
          mode = { width = 3840; height = 2160; refresh = 60.0; };
          scale = 1.5;
          variable-refresh-rate = true;
        };
      };

      environment = {
        STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
      };

      # Startup workspace comes from hostParams.desktop.startupWorkspace.
      spawn-at-startup = [
        { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
      ];

      binds = {
        # Dictation toggles. All three are toggle-style (press to start,
        # press again to stop/transcribe), so they MUST have repeat=false --
        # otherwise niri's default ~500 ms key-repeat fires the toggle again
        # before you've released the key, yielding start/stop/start/stop
        # chaos (empty transcripts, partial words, windows moving as
        # mid-flight keystrokes race with the repeating hotkey).
        # cooldown-ms is a belt-and-suspenders debounce against double-taps.
        # mkForce is needed because modules/desktop/niri/home.nix ships
        # defaults on these keys (consume-window-into-column etc).
        "Mod+Comma" = lib.mkForce {
          repeat = false;
          cooldown-ms = 500;
          hotkey-overlay.title = "Dictation: nerd-dictation (Vosk, streaming)";
          action.spawn = [ "nerd-dictation-toggle" ];
        };
        "Mod+Period" = lib.mkForce {
          repeat = false;
          cooldown-ms = 500;
          hotkey-overlay.title = "Dictation: whisper-dictate (whisper.cpp, batch)";
          action.spawn = [ "whisper-dictate" ];
        };
        # Mod+Slash intentionally not overridden here. Previously bound
        # to moonshine-dictate; moonshine was dropped in favour of
        # nerd-dictation (streaming, Mod+Comma) + whisper-dictate (batch,
        # Mod+Period) after moonshine's medium-streaming model proved too
        # inaccurate for useful dictation. Keep the moonshine packaging in
        # pkgs/ for future experiments.
      };

      # Workspace names and their output come from nixcfg-niri
      # (hostParams.desktop.workspaceOutput).
    };
  };
}
