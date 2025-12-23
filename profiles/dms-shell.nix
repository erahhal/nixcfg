{ config, lib, pkgs, inputs, system, ... }:
{
  config = lib.mkIf (config.hostParams.desktop.displayManager == "dms" && config.hostParams.programs.steam.bootToSteam == false) {
    programs.dank-material-shell.enable = true;

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };

    services.greetd.enable = true;
  };
}
