{ pkgs, userParams, ... }:

let
  captive-portal-dispatcher = pkgs.writeShellScriptBin "90-captive-portal.sh" ''
    # Auto-open browser when NetworkManager detects a captive portal.
    # Dispatcher scripts run as root, so we need to launch the browser
    # as the logged-in user with the correct graphical session environment.

    NMCLI=${pkgs.networkmanager}/bin/nmcli
    LOGGER="${pkgs.util-linux}/bin/logger -t captive-portal"

    if [ "$2" != "connectivity-change" ]; then
        exit 0
    fi

    CONNECTIVITY=$($NMCLI -t -f CONNECTIVITY general 2>/dev/null)

    if [ "$CONNECTIVITY" != "portal" ]; then
        exit 0
    fi

    # Debounce: don't open multiple browser windows for the same portal
    LOCK="/tmp/captive-portal-detected"
    if [ -f "$LOCK" ]; then
        # If lock is older than 60 seconds, remove it (portal might be new)
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

    # Find the user's graphical session and set up environment
    SESSION_ID=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk -v user="$USERNAME" '$3 == user {print $1; exit}')

    if [ -z "$SESSION_ID" ]; then
        $LOGGER "No session found for $USERNAME"
        rm -f "$LOCK"
        exit 0
    fi

    # Get session type (wayland or x11)
    SESSION_TYPE=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Type --value 2>/dev/null)

    # Get the runtime dir and display info
    USER_ID=$(${pkgs.coreutils}/bin/id -u "$USERNAME")
    RUNTIME_DIR="/run/user/$USER_ID"

    if [ "$SESSION_TYPE" = "wayland" ]; then
        DISPLAY_VAR="WAYLAND_DISPLAY"
        DISPLAY_VAL=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Display --value 2>/dev/null)
        # Wayland display is typically "wayland-0" or "wayland-1"
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

    # Launch browser as the user
    ${pkgs.sudo}/bin/sudo -u "$USERNAME" \
        XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        "$DISPLAY_VAR=$DISPLAY_VAL" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus" \
        ${pkgs.xdg-utils}/bin/xdg-open "http://neverssl.com" &

    $LOGGER "Browser launched for captive portal"
  '';
in
{
  networking.networkmanager = {
    # Enable connectivity checking so NM can detect captive portals
    settings.connectivity = {
      uri = "http://nmcheck.gnome.org/check_network_status.txt";
      response = "NetworkManager is online\n";
      interval = 300;
    };

    # Dispatcher script to auto-open browser on portal detection
    dispatcherScripts = [
      {
        source = "${captive-portal-dispatcher}/bin/90-captive-portal.sh";
      }
    ];
  };
}
