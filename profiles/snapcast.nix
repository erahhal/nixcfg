{ pkgs, lib, userParams, ... }:
{
  home-manager.users.${userParams.username} = { pkgs, ... }: {
    xdg.configFile."pipewire/pipewire.conf.d/snapcast-pipe-tunnel.conf".text = ''
      context.modules = [
        {
          name = libpipewire-module-pipe-tunnel
          args = {
            tunnel.mode = sink
            ## Must be in folder created by snapserver, otherwise
            ## snapserver will not be able to read from it
            # pipe.filename = "/run/snapserver/pipewire_snapcast_pipe"
            pipe.filename = "/tmp/pipewire_snapcast_pipe"
            node.name = "snapcast"
            audio.rate = 44100
            audio.channels = 2
            audio.format = S16LE
          }
        }
      ]
    '';
  };

  services.snapserver = {
    enable = true;
    codec = "flac";
    sampleFormat = "44100:16:2";
    streams = {
      a_main = {
        type = "meta";
        location = "/p_pipewire";
      };
      p_pipewire = {
        type = "pipe";
        # location = "/run/snapserver/pipewire_snapcast_pipe";
        location = "/tmp/pipewire_snapcast_pipe";
      };
    };
    openFirewall = true;
  };

  ## Hacky way to get it to read /tmp/pipewire_snapcast_pipe
  systemd.services.snapserver = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      RestrictNamespacaes = lib.mkForce false;
      Type = lib.mkForce "simple";
      ExecStart = lib.mkForce ''${pkgs.snapcast}/bin/snapserver --stream.stream="meta:///p_pipewire?name=a_main" --stream.stream="pipe:///tmp/pipewire_snapcast_pipe?name=p_pipewire" --stream.bind_to_address=:: --stream.port=1704 --stream.sampleformat=44100:16:2 --stream.codec=flac --tcp.enabled=1 --tcp.bind_to_address=:: --tcp.port=1705 --http.bind_to_address=::'';
    };
  };


  # Should not be needed with openFirewall property above also set
  networking.firewall.allowedTCPPorts = [ 1704 1705 1780 ];
}
