{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.keyboard-debounce;
  debouncer-udevmon = pkgs.callPackage ../../../pkgs/debouncer-udevmon {};

  debouncerConfig = pkgs.writeText "debouncer.toml" ''
    exceptions = [29, 42, 54, 56, 97, 100, 125]
    debounce_time = 14
  '';
in {
  options.nixcfg.hardware.keyboard-debounce = {
    enable = lib.mkEnableOption "keyboard debounce (Keychron wireless)";
  };
  config = lib.mkIf cfg.enable {
    services.interception-tools = {
      enable = true;
      plugins = [ debouncer-udevmon ];
      udevmonConfig = ''
        - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${debouncer-udevmon}/bin/debouncer-udevmon | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_A]
            NAME: ".*[Kk]eychron.*"
      '';
    };

    environment.etc."debouncer.toml".source = debouncerConfig;

    environment.systemPackages = [ pkgs.via ];
    services.udev.packages = [ pkgs.via ];
  };
}
