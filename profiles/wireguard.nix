{ config, pkgs, hostParams, ... }:
let
  wg0-scripts = pkgs.callPackage ../pkgs/wg0-scripts { secrets = config.age.secrets; };
  wg-port-num = 64210;
  wg-port = toString wg-port-num;
in
{
  environment.systemPackages = with pkgs; [
    wg0-scripts
  ];

  networking.firewall = {
    allowedUDPPorts = [ wg-port-num ];
    # if packets are still dropped, they will show up in dmesg
    logReversePathDrops = true;
    # wireguard trips rpfilter up
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport ${wg-port} -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport ${wg-port} -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport ${wg-port} -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport ${wg-port} -j RETURN || true
    '';
  };

  environment.etc."NetworkManager/system-connections/wg0.nmconnection" = {
    mode = "0600";
    text = ''
      [connection]
      id=wg0
      type=wireguard
      interface-name=wg0
      autoconnect=false
      post-up=iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp0s20f3 -j MASQUERADE
      post-down=iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp0s20f3 -j MASQUERADE

      [wireguard]
      listen-port=${wg-port}
      # private-key=

      [wireguard-peer.EpIitQWn0xHvMj0q8MgKgrDA8lqqm+saDdgk8PwiQXw=]
      fwmark=1280
      endpoint=rahh.al:${wg-port}
      persistent-keepalive=120
      allowed-ips=10.0.0.0/24;192.168.2.0/24;

      [ipv4]
      address1=${hostParams.wireguardIp}/32
      dns=192.168.2.1;
      dns-search=localdomain;rahh.al;
      method=manual

      [ipv6]
      addr-gen-mode=stable-privacy
      method=disabled

      [proxy]
    '';
  };
}
