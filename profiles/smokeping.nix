{ config, pkgs, ... }:
{
  # Open port for smokeping
  networking.firewall.allowedTCPPorts = [ 8081 ];
  services.smokeping = {
    enable = true;
    host = "0.0.0.0";
    hostName = "smokeping";
    targetConfig = ''
      probe = FPing

      menu = Top
      title = Network Latency Grapher
      remark = Welcome to SmokePing

      + google
      menu = Google
      title = google Network

      ++ googlesite
      host = google.com
      ++ googledns
      host = 8.8.8.8

      + spectrum
      menu = Spectrum
      title = Spectrum

      ++ spectrumgw
      host = 172.250.0.1

      + nas
      menu = NAS
      title = NAS

      ++ nasserver
      host = nas.localdomain
    '';
  };
}
