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
            node.description = "Snapcast"
            audio.rate = 44100
            audio.channels = 2
            audio.format = S16LE
          }
        }
      ]
    '';
  };

  # services.snapserver = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {
  #     stream = {
  #       codec = "flac";
  #       sampleFormat = "44100:16:2";
  #       source = [
  #         "meta:///p_pipewire?name=a_main"
  #         "pipe:///tmp/pipewire_snapcast_pipe?name=p_pipewire"
  #       ];
  #     };
  #   };
  # };

  environment.etc."snapserver.conf" = {
    text = ''
      [stream]
      codec = flac
      sampleFormat = 44100:16:2
      source = meta:///p_pipewire?name=a_main
      source = pipe:///tmp/pipewire_snapcast_pipe?name=p_pipewire
      bind_to_address = ::
      port = 1704

      [tcp]

      enabled = 1
      bind_to_address = ::
      port = 1705

      [http]
      bind_to_address = ::
    '';
    mode = "0644";
  };

  ## Hacky way to get it to read /tmp/pipewire_snapcast_pipe
  systemd.services.snapserver = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    description = "Snapcast Server";
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
      Type = lib.mkForce "simple";
      # ExecStart = lib.mkForce ''${pkgs.snapcast}/bin/snapserver --stream.stream="meta:///p_pipewire?name=a_main" --stream.stream="pipe:///tmp/pipewire_snapcast_pipe?name=p_pipewire" --stream.bind_to_address=:: --stream.port=1704 --stream.sampleformat=44100:16:2 --stream.codec=flac --tcp.enabled=1 --tcp.bind_to_address=:: --tcp.port=1705 --http.bind_to_address=::'';
      ExecStart = lib.mkForce ''${pkgs.snapcast}/bin/snapserver'';
      Restart = "on-failure";
    };
  };


  # Should not be needed with openFirewall property above also set
  networking.firewall.allowedTCPPorts = [ 1704 1705 1780 ];
}
