#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nftables -p dnsmasq -p iw -p gawk -p gnugrep

## See: https://nixos.wiki/wiki/Internet_Connection_Sharing

WIFI_INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
# gets first physical interface that starts with the letter "e"
ETH_INTERFACE=$(find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n' | grep "^e" | head -n 1)

up () {
    # Setup ethernet device
    ip link set up $ETH_INTERFACE
    ip addr add 10.3.0.1/24 dev $ETH_INTERFACE

    # Enable packet forwarding
    sysctl net.ipv4.ip_forward=1

    # Enable NAT for leaving packets
    nft add rule nat POSTROUTING oifname $WIFI_INTERFACE masquerade

    # socat UDP-LISTEN:53,fork,reuseaddr,bind=10.3.0.1 UDP:127.0.0.53:53

    # Start dnsmasq for DHCP
    # -p0 disables DNS
    # --server=10.3.0.1 specifies DNS server to use
    # --dhcp-option=6,10.3.0.1 forces client to use DNS server
    dnsmasq -d -p0 --server=10.3.0.1 --dhcp-option=6,10.3.0.1 -i $ETH_INTERFACE --dhcp-range=10.3.0.2,10.3.0.255,255.255.255.0,24h

    down
}

down () {
    pkill socat
    ip addr del 10.3.0.1/24 dev $ETH_INTERFACE
    ip link set down $ETH_INTERFACE
    while nft -a list table nat | grep -q $WIFI_INTERFACE; do
        HANDLE_NUM=$(nft -a list table nat | grep $WIFI_INTERFACE | head -n 1 | awk '{ print $6 }')
        nft delete rule nat POSTROUTING handle $HANDLE_NUM
    done
}

up
