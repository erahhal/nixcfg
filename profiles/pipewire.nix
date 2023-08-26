{ pkgs, userParams, ... }:

{
  # @TODO: Revert this when stable is at least 0.3.77
  services.pipewire.package = pkgs.unstable.pipewire;

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
    # for pactl
    pulseaudio
  ];
}
