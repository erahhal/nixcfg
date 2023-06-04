{ config, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 24800 ];
  services.synergy = {
    server = {
      enable = true;
      configFile = pkgs.writeTextFile {
        name = "synergy-server.conf";
        text = ''
          section: screens
              upaya:
              nflx-erahhal-t490s:
              # enable this if using a macbook
              macbook:
                  super = alt
                  alt = super
          end

          section: links
              upaya:
                  right(0, 50) = nflx-erahhal-t490s(65, 100)
              nflx-erahhal-t490s:
                  left(65, 100) = upaya(0, 50)
          end
        '';
      };
      screenName = "upaya";
      autoStart = true;
    };
  };
}
