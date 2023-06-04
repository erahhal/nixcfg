{ pkgs, fetchFromGithub, ...}:

let
  systemd-networkd-dns = pkgs.buildGoModule {
    src = fetchFromGithub {
      owner = "FiloSottile";
      repo = "captive-browser";
      rev = "9c707dc32afc6e4146e19b43a3406329c64b6f3c";
      sha256 = "1xhz009f01a55fm5p191h1gqfasmbhwrgbrcawzl64v9kfilz6gb";
    } + "/cmd/systemd-networkd-dns";

    vendorSha256 = "blah";
  };
in
{
  home.packages = with pkgs; [ captive-browser systemd-networkd-dns ];

  xdg.configFile."captive-browser.toml".text = ''
    # browser is the shell (/bin/sh) command executed once the proxy starts.
    # When browser exits, the proxy exits. An extra env var PROXY is available.
    #
    # Here, we use a separate Chrome instance in Incognito mode, so that
    # it can run (and be waited for) alongside the default one, and that
    # it maintains no state across runs. To configure this browser open a
    # normal window in it, settings will be preserved.
    browser = """
        chromium-browser \
        --user-data-dir="$HOME/.google-chrome-captive" \
        --proxy-server="socks5://$PROXY" \
        --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost" \
        --no-first-run --new-window --incognito \
        http://neverssl.com
    """

    # dhcp-dns is the shell (/bin/sh) command executed to obtain the DHCP
    # DNS server address. The first match of an IPv4 regex is used.
    # IPv4 only, because let's be real, it's a captive portal.
    #
    # `wlp3s0` is your network interface (eth0, wlan0 ...)
    #
    # To install the systemd-networkd-dns command, run:
    #
    #  $ go get github.com/FiloSottile/captive-browser/cmd/systemd-networkd-dns
    #
    dhcp-dns = "$(go env GOPATH)/bin/systemd-networkd-dns wlp0s20f3"

    # socks5-addr is the listen address for the SOCKS5 proxy server.
    socks5-addr = "localhost:1666"

    # bind-device is the interface over which outbound connections (both HTTP
    # and DNS) will be established. It can be used to avoid address space collisions
    # but it requires CAP_NET_RAW or root privileges. Disabled by default.
    #bind-device = "wlan0"
  '';
}
