{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.desktop.pipewire;
in {
  options.nixcfg.desktop.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio";
  };
  config = lib.mkIf cfg.enable {
    users.users."${userParams.username}" = {
      extraGroups = [
        "audio"
        "rtkit"
        "video"
      ];
    };

    hardware.enableAllFirmware = true;

    # Enable the Real-Time Kit for improved performance
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      ## Should be default enabled
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
      # for pactl
      pulseaudio
    ];
  };
}
