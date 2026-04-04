{ config, lib, pkgs, userParams, ... }:
let
  cfg = config.nixcfg.desktop.dms;
  dms-command-runner = pkgs.fetchFromGitHub {
    owner = "devnullvoid";
    repo = "dms-command-runner";
    rev = "f5f676fe49d2cde86054a28ed06f824319cd5193";
    hash = "sha256-oIzhogusDzXJ7KH/Kmu3euuBCiTJ5GAH8ho24MmXARI=";
  };

  dms-easyeffects = pkgs.applyPatches {
    src = pkgs.fetchFromGitHub {
      owner = "jonkristian";
      repo = "dms-easyeffects";
      rev = "f50fdb7a110ddb90b7625bc143884fd773c3d5c7";
      hash = "sha256-q0Xp4RzHd0HgtUZEM4hIES6SDyN8R4lPgQe5aeLMh4c=";
    };
    patches = [
      ./patches/dms-easyeffects-fix-hang.patch
    ];
  };

  dms-network-monitor = pkgs.callPackage ../../../pkgs/dms-network-monitor {};
in
{
  key = "nixcfg/desktop/dms";

  options.nixcfg.desktop.dms.enable = lib.mkEnableOption "DMS shell desktop environment";

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      plugins = {
        CommandRunner = {
          enable = true;
          src = dms-command-runner;
        };
        NetworkMonitor = {
          enable = true;
          src = dms-network-monitor;
        };
        EasyEffects = {
          enable = true;
          src = dms-easyeffects;
        };
      };
      enableSystemMonitoring = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = false; # khal 0.13.0 fails to build (sphinx bug)

      greeter = lib.mkIf (!config.hostParams.desktop.autoLogin) {
        enable = true;
        compositor.name = "niri";
        logs.save = true;
        compositor.customConfig = ''
          hotkey-overlay {
              // disable the "Important Hotkeys" pop-up at startup.
              skip-at-startup
          }
        '';
      };
    };

    # Enable automatic keyring/wallet unlock via PAM when logging in through DMS greeter
    security.pam.services.dms-greeter = {
      enableGnomeKeyring = true;
      enableKwallet = true;
    };

    services.greetd = {
      enable = true;
      settings = lib.mkIf config.hostParams.desktop.autoLogin {
        default_session = {
          command = "niri-session";
          user = userParams.username;
        };
      };
    };
  };
}
