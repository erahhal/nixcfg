# Private Internet Access

# Start with:
#   sudo systemctl start openvpn-us-east.service

{ config, pkgs, userParams, ... }:
let
  base_config = ''
    client
    dev tun
    proto udp
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    cipher aes-128-cbc
    auth sha1
    tls-client
    remote-cert-tls server
    auth-user-pass
    compress
    verb 1
    reneg-sec 0
    crl-verify /home/${userParams.username}/pia-config/crl.rsa.2048.pem
    ca /home/${userParams.username}/pia-config/ca.rsa.2048.crt
    disable-occ
    ; auth-user-pass /home/${userParams.username}/pia-config/pia-login.conf
    auth-user-pass ${config.age.secrets.pia-auth-conf.path}
  '';
  up_cmd = "echo nameserver $nameserver | ${pkgs.systemd}/bin/resolvconf -m 0 -a $dev";
  down_cmd = "${pkgs.systemd}/bin/resolvconf -d $dev";
in
{
  home-manager.users.${userParams.username} = {
    home.file."pia-config/ca.rsa.2048.crt".source = ../dotfiles/pia-config/ca.rsa.2048.crt;
    home.file."pia-config/crl.rsa.2048.pem".source = ../dotfiles/pia-config/crl.rsa.2048.pem;
  };

  services.openvpn = {
    servers = {
      albania = {
        config = base_config + ''
          remote al.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      algeria = {
        config = base_config + ''
          remote dz.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      andorra = {
        config = base_config + ''
          remote ad.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      argentina = {
        config = base_config + ''
          remote ar.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      armenia = {
        config = base_config + ''
          remote yerevan.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      au-melbourne = {
        config = base_config + ''
          remote aus-melbourne.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      au-perth = {
        config = base_config + ''
          remote aus-perth.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      au-sydney = {
        config = base_config + ''
          remote aus-sydney.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      austria = {
        config = base_config + ''
          remote austria.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      bahamas = {
        config = base_config + ''
          remote bahamas.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      bangladesh = {
        config = base_config + ''
          remote bangladesh.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      belgium = {
        config = base_config + ''
          remote brussels.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      brazil = {
        config = base_config + ''
          remote br.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      bulgaria = {
        config = base_config + ''
          remote sofia.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      ca-montreal = {
        config = base_config + ''
          remote ca-montreal.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      ca-ontario = {
        config = base_config + ''
          remote ca-ontario.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      ca-toronto = {
        config = base_config + ''
          remote ca-toronto.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      cambodia = {
        config = base_config + ''
          remote cambodia.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      china = {
        config = base_config + ''
          remote china.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };


      us-california = {
        config = base_config + ''
          remote us-california.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      us-chicago = {
        config = base_config + ''
          remote us-chicago.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
      us-east = {
        config = base_config + ''
          remote us-newjersey.privacy.network 1198
        '';
        autoStart = false;
        up = up_cmd;
        down = down_cmd;
      };
    };
  };
}
