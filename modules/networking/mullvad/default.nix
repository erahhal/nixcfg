{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.mullvad;
in {
  options.nixcfg.networking.mullvad = {
    enable = lib.mkEnableOption "Mullvad VPN";
  };
  config = lib.mkIf cfg.enable {
    # CLI documentation: https://mullvad.net/en/help/how-use-mullvad-cli/

    # mullvad account set <account number>
    # mullvad local set allow
    # mullvad relay set location ca
    # mullvad dns set custom 10.0.0.1
    # mullvad dns set default
    # mullvad connect
    # mullvad disconnect

    environment.systemPackages = with pkgs; [
      mullvad
      mullvad-compass
    ];

    services.mullvad-vpn = {
      enable = true;
    };
  };
}
