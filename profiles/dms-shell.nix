{ config, lib, ... }:
{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "dms" && config.hostParams.programs.steam.bootToSteam == false) {
    programs.dankMaterialShell.enable = true;

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };

    services.greetd.enable = true;
  };
}
