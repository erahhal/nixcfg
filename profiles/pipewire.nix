{ pkgs, userParams, ... }:

{
  # SEE: https://nixos.wiki/wiki/PipeWire

  # Using pipewire instead
  # hardware.pulseaudio.enable = false;

  users.users."${userParams.username}" = {
    extraGroups = [
      "audio"
      "rtkit"
      "video"
    ];
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
  ];
}
