{ config, pkgs, userParams, ... }:
{
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
    mullvad-closest
  ];

  services.mullvad-vpn = {
    enable = true;
  };

}
