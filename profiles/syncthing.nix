{ userParams, ...}:
{
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  home-manager.users.${userParams.username} = {
    services.syncthing = {
      enable = true;
      tray.enable = true;
    };
  };
}
