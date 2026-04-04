{ config, lib, pkgs, userParams, ... }:
let
  cfg = config.nixcfg.networking.captive-portal;

  captive-portal-dispatcher = pkgs.writeShellScriptBin "90-captive-portal.sh" ''
    NMCLI=${pkgs.networkmanager}/bin/nmcli
    LOGGER="${pkgs.util-linux}/bin/logger -t captive-portal"

    if [ "$2" != "connectivity-change" ]; then
        exit 0
    fi

    CONNECTIVITY=$($NMCLI -t -f CONNECTIVITY general 2>/dev/null)

    if [ "$CONNECTIVITY" != "portal" ]; then
        exit 0
    fi

    LOCK="/tmp/captive-portal-detected"
    if [ -f "$LOCK" ]; then
        if [ "$(find "$LOCK" -mmin +1 2>/dev/null)" ]; then
            rm -f "$LOCK"
        else
            $LOGGER "Portal detected but browser already opened recently, skipping"
            exit 0
        fi
    fi
    touch "$LOCK"

    $LOGGER "Captive portal detected, opening browser"

    USERNAME="${userParams.username}"

    SESSION_ID=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk -v user="$USERNAME" '$3 == user {print $1; exit}')

    if [ -z "$SESSION_ID" ]; then
        $LOGGER "No session found for $USERNAME"
        rm -f "$LOCK"
        exit 0
    fi

    SESSION_TYPE=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Type --value 2>/dev/null)

    USER_ID=$(${pkgs.coreutils}/bin/id -u "$USERNAME")
    RUNTIME_DIR="/run/user/$USER_ID"

    if [ "$SESSION_TYPE" = "wayland" ]; then
        DISPLAY_VAR="WAYLAND_DISPLAY"
        DISPLAY_VAL=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Display --value 2>/dev/null)
        if [ -z "$DISPLAY_VAL" ] || [ "$DISPLAY_VAL" = "-" ]; then
            DISPLAY_VAL="wayland-1"
        fi
    else
        DISPLAY_VAR="DISPLAY"
        DISPLAY_VAL=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Display --value 2>/dev/null)
        if [ -z "$DISPLAY_VAL" ]; then
            DISPLAY_VAL=":0"
        fi
    fi

    ${pkgs.sudo}/bin/sudo -u "$USERNAME" \
        XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        "$DISPLAY_VAR=$DISPLAY_VAL" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus" \
        ${pkgs.xdg-utils}/bin/xdg-open "http://neverssl.com" &

    $LOGGER "Browser launched for captive portal"
  '';
in {
  options.nixcfg.networking.captive-portal = {
    enable = lib.mkEnableOption "auto-open browser on captive portal detection";
  };
  config = lib.mkIf cfg.enable {
    networking.networkmanager = {
      settings.connectivity = {
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        response = "NetworkManager is online\n";
        interval = 300;
      };
      dispatcherScripts = [
        { source = "${captive-portal-dispatcher}/bin/90-captive-portal.sh"; }
      ];
    };
  };
}
