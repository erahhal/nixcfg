{ userParams, ...}:
{
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  home-manager.users.${userParams.username} = {
    services.syncthing = {
      enable = true;
      ## Causes an error on startup
      # tray.enable = true;
    };
  };
}
