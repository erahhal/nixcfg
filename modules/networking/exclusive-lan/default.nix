{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.networking.exclusive-lan;

  exclusive-lan = pkgs.writeShellScriptBin "70-wifi-wired-exclusive.sh" ''
    NMCLI=${pkgs.networkmanager}/bin/nmcli
    GREP=${pkgs.gnugrep}/bin/grep

    export LC_ALL=C

    enable_disable_wifi ()
    {
        result=$($NMCLI dev | $GREP "ethernet" | $GREP -w "connected")
        if [ -n "$result" ]; then
            $NMCLI radio wifi off
        else
            $NMCLI radio wifi on
            sleep 2
            $NMCLI device wifi rescan || true
        fi
    }

    if [ "$2" = "up" ]; then
        enable_disable_wifi
    fi

    if [ "$2" = "down" ]; then
        enable_disable_wifi
    fi

    if [ "$2" = "connectivity-change" ]; then
        enable_disable_wifi
    fi
  '';
in {
  options.nixcfg.networking.exclusive-lan = {
    enable = lib.mkEnableOption "mutually exclusive WiFi/wired networking";
  };
  config = lib.mkIf cfg.enable {
    networking = {
      wireless.enable = false;
      networkmanager.dispatcherScripts = [
        { source = "${exclusive-lan}/bin/70-wifi-wired-exclusive.sh"; }
      ];
    };
  };
}
