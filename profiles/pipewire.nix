{ pkgs, userParams, ... }:

{
  # SEE: https://nixos.wiki/wiki/PipeWire

  # Using pipewire instead
  hardware.pulseaudio.enable = false;

  security.rtkit.enable = true;
  users.users."${userParams.username}" = {
    extraGroups = [
      "audio"
      "rtkit"
      "video"
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    # pulseaudio
  ];
}
