{ config, lib, ... }:
{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "dms" && config.hostParams.programs.steam.bootToSteam == false) {
    programs.dank-material-shell.enable = true;

    services.displayManager.dms-greeter = {
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

    services.greetd.enable = true;
  };
}
