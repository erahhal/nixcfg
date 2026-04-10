{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.services.snapcast;
in {
  options.nixcfg.services.snapcast = {
    enable = lib.mkEnableOption "Snapcast audio streaming server";
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${userParams.username} = { pkgs, ... }: {
      xdg.configFile."pipewire/pipewire.conf.d/snapcast-pipe-tunnel.conf".text = ''
        context.modules = [
          {
            name = libpipewire-module-pipe-tunnel
            args = {
              tunnel.mode = sink
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

    systemd.services.snapserver = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "Snapcast Server";
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        RestrictNamespaces = lib.mkForce false;
        Type = lib.mkForce "simple";
        ExecStart = lib.mkForce ''${pkgs.snapcast}/bin/snapserver'';
        Restart = "on-failure";
      };
    };

    networking.firewall.allowedTCPPorts = [ 1704 1705 1780 ];
  };
}
