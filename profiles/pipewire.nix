{ pkgs, userParams, ... }:

{
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

  # home-manager.users.${userParams.username} = { pkgs, ... }: {
  #   xdg.configFile."wireplumber/bluetooth.lua.d/bluez-config.lua".text = ''
  #     bluez_monitor.properties = {
  #       ["bluez5.enable-sbc-xq"] = true,
  #       ["bluez5.enable-msbc"] = true,
  #       ["bluez5.enable-hw-volume"] = true,
  #       ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
  #     }
  #   '';
  # };
}
