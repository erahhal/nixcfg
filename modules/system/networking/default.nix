# Base networking: hostname, NetworkManager, resolved, wait-online
# Uses lib.mkDefault so hosts can override specific settings
{ config, lib, ... }:
{
  networking = {
    hostName = config.hostParams.system.hostName;
    search = [];

    useNetworkd = lib.mkDefault true;
    networkmanager = {
      enable = lib.mkDefault true;
      wifi = {
        backend = lib.mkDefault "iwd";
        powersave = lib.mkDefault false;
        scanRandMacAddress = lib.mkDefault false;
      };
    };
    wireless = {
      enable = lib.mkDefault false;
      iwd = {
        enable = lib.mkDefault true;
        settings = {
          General.EnableNetworkConfiguration = lib.mkDefault false;
          Settings.AutoConnect = lib.mkDefault true;
        };
      };
    };
  };

  services.resolved = {
    enable = lib.mkDefault true;
    settings.Resolve.DNSSEC = lib.mkDefault "false";
  };

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = lib.mkDefault true;
  systemd.network.wait-online.enable = lib.mkDefault false;
  systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;
}
