{ osConfig, lib, inputs, pkgs, ... }:

let
  niri = "${pkgs.niri}/bin/niri";
  jq = "${pkgs.jq}/bin/jq";
  rofi = ''"${pkgs.rofi}/bin/rofi" "-show" "drun" "-theme" "~/.config/rofi/launcher.rasi"'';
  ## @TODO: Move to a service
  dynamic-float-rules = pkgs.callPackage ./niri/dynamic-float-rules.nix {};
  toggle-fcitx = pkgs.writeShellScript "toggle-fcitx" ''
    if systemctl --user is-active --quiet fcitx5-daemon; then
      systemctl --user stop fcitx5-daemon
    else
      systemctl --user start fcitx5-daemon
    fi
  '';
  exit-niri = pkgs.writeShellScript "exit-niri" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    pkill niri
  '';
  reboot = pkgs.writeShellScript "kill-reboot" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    systemctl reboot
  '';
  poweroff = pkgs.writeShellScript "kill-poweroff" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    systemctl poweroff
  '';

  kill-active = pkgs.writeShellScript "niri-kill-active.sh" ''
    if [ "$(${niri} msg -j focused-window | ${jq} -r ".app_id")" = "Steam" ]; then
        ${pkgs.xdotool}/bin/xdotool getactivewindow windowunmap
    elif [ "$(${niri} msg -j focused-window | ${jq} -r ".app_id")" = "foot" ]; then
        echo "Not closing."
    else
        ${niri} msg action close-window
    fi
  '';

  focus-with-overview = pkgs.writeShellScript "focus-with-overview" ''
    # Script to handle focus commands with overview toggling and debouncing
    # Usage: ./niri-focus-with-overview.sh <focus-command>

    TIMESTAMP_FILE="/tmp/niri-focus-timestamp"
    TIMEOUT=0.3  # seconds

    FOCUS_CMD="$1"
    [ -z "$FOCUS_CMD" ] && { echo "Usage: $0 <focus-command>"; exit 1; }
    NO_TOGGLE="$2"

    # Background function to close overview after timeout
    close_after_timeout() {
        local timestamp="$1"
        sleep "$TIMEOUT"

        # Only close if our timestamp is still current
        [ -f "$TIMESTAMP_FILE" ] && [ "$(cat "$TIMESTAMP_FILE" 2>/dev/null)" = "$timestamp" ] && {
            rm -f "$TIMESTAMP_FILE"
            ${niri} msg action close-overview
        }
    }

    # Generate unique timestamp
    TIMESTAMP="$(date +%s%N)"

    # If timestamp file exists, we're already in overview mode
    if [ -f "$TIMESTAMP_FILE" ]; then
        # Just execute focus command and update timestamp
        ${niri} msg action "$FOCUS_CMD"
        echo "$TIMESTAMP" > "$TIMESTAMP_FILE"
    else
        if [ -z "$NO_TOGGLE"]; then
          # First invocation - open overview and execute focus
          ${niri} msg action open-overview
        fi
        ${niri} msg action "$FOCUS_CMD"
        echo "$TIMESTAMP" > "$TIMESTAMP_FILE"
    fi

    # Start timeout with our timestamp
    close_after_timeout "$TIMESTAMP" &
  '';

  toggle-tabbed = pkgs.writeShellScript "niri-toggle-tabbed" ''
    # Get current workspace ID from focused window
    current_workspace=$(niri msg -j focused-window | jq -r '.workspace_id // empty')

    # If no focused window, get first workspace with windows
    if [ -z "$current_workspace" ]; then
        current_workspace=$(niri msg -j windows | jq -r '.[0].workspace_id // empty')
    fi

    # Exit if no workspace found
    [ -z "$current_workspace" ] && exit 0

    # Get all windows in current workspace
    windows=$(niri msg -j windows | jq -r ".[] | select(.workspace_id == $current_workspace) | .id")

    # Convert to array
    window_ids=($windows)

    # Exit if no windows
    [ ''${#window_ids[@]} -eq 0 ] && exit 0

    # Exit if only one window (nothing to group)
    [ ''${#window_ids[@]} -eq 1 ] && exit 0

    # Much simpler approach: just use consume-window-into-column sequentially
    # Focus first window
    niri msg action focus-window --id "''${window_ids[0]}"

    # Consume each subsequent window into the focused column
    for ((i=1; i<''${#window_ids[@]}; i++)); do
        window_id="''${window_ids[i]}"
        niri msg action focus-window --id "$window_id"
        niri msg action consume-window-into-column
    done

    # Toggle the column to tabbed display
    niri msg action focus-window --id "''${window_ids[0]}"
    niri msg action toggle-column-tabbed-display
  '';

  switch-preset-column-width-all = pkgs.writeShellScript "switch-preset-column-width-all" ''
    active_workspace=$(${niri} msg -j workspaces | ${jq} -r '.[] | select(.is_active == true) | .id')
    # Get all windows and filter for current workspace
    # Apply width change to each window
    for window_id in $(${niri} msg -j windows | ${jq} -r ".[] | select(.workspace_id == $active_workspace) | .id"); do
        ${niri} msg action switch-preset-window-width --id "$window_id"
    done
  '';

  kill-active-force = pkgs.writeShellScript "niri-kill-active-force.sh" ''
    ${niri} msg -j focused-window | ${jq} '.pid' | ${pkgs.findutils}/bin/xargs -L 1 kill -9
  '';

  capture-screen = pkgs.writeShellScript "niri-capture-screen.sh" ''
    ${pkgs.grim}/bin/grim -o $(${niri} msg -j focused-output | jq -r '.name') - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
  '';

  capture-selection = pkgs.writeShellScript "niri-capture-selection.sh" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
  '';

  capture-window = pkgs.writeShellScript "niri-capture-window.sh" ''
    offset_x=$(${niri} msg -j focused-window | jq -r '.layout.window_offset_in_tile[0]')
    offset_x=$(printf "%.0f" "$offset_x")
    offset_y=$(${niri} msg -j focused-window | jq -r '.layout.window_offset_in_tile[1]')
    offset_y=$(printf "%.0f" "$offset_y")
    size=$(${niri} msg -j focused-window | jq -r '.layout.window_size | join("x")')
    offset="$offset_x,$offset_y $size"
    ${pkgs.grim}/bin/grim -g "$offset" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
  '';


  nag-graphical = pkgs.callPackage ../../pkgs/nag-graphical {};

  reboot-dialog = pkgs.writeShellScript "reboot-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Reboot?' 'systemctl reboot'
  '';

  suspend-dialog = pkgs.writeShellScript "suspend-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Suspend?' '${hyprlockCommand} suspend'
  '';

  wallpaper-cmd = if (osConfig.hostParams.desktop.wallpaper != null) then pkgs.writeShellScript "niri-wallpaper" ''
    killall hyprpaper
    killall mpvpaper
    killall swaybg
    # ${pkgs.swaybg}/bin/swaybg -i "$(${pkgs.findutils}/bin/find ~/.config/wallpapers/. -type f| ${pkgs.coreutils}/bin/shuf -n1)"
    # ${pkgs.swaybg}/bin/swaybg -i ${osConfig.hostParams.desktop.wallpaper} -m fill
    ${pkgs.hyprpaper}/bin/hyprpaper
  '' else "";

  ## This is fun, but eats up a ton of GPU
  wallpaper-animated = pkgs.writeShellScript "niri-wallpaper-animated" ''
    killall hyprpaper
    killall swaybg
    killall mpvpaper
    # ${pkgs.mpvpaper}/bin/mpvpaper '*' -o "no-audio --panscan=1.0 --loop-file=inf --loop-playlist=inf" "$(${pkgs.findutils}/bin/find ~/Videos/backgrounds/. -type f| ${pkgs.coreutils}/bin/shuf -n1)"
    ${pkgs.mpvpaper}/bin/mpvpaper '*' -o "no-audio --panscan=1.0 --loop-file=inf --loop-playlist=inf" ~/Videos/backgrounds
  '';

  swayLockCommand = pkgs.callPackage ../../pkgs/sway-lock-command { };
  ## @TODO: Currently locks before suspending. Could cause problems?
  ## See:   https://github.com/hyprwm/hyprlock/issues/65#issuecomment-2468337543
  hyprlockCommand = pkgs.callPackage ../../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };

  # Create a script to toggle between inputs only on P40w-20 monitors
  toggle-thinkvision-input = pkgs.writeShellScript "toggle-input" ''
    # Check if P40w-20 monitor is connected
    MONITOR_CONNECTED=$(${pkgs.ddcutil}/bin/ddcutil detect | grep -i "P40w-20")

    if [ -z "$MONITOR_CONNECTED" ]; then
      echo "ThinkVision P40w-20 monitor not detected. No action taken."
      exit 1
    fi

    # Get the monitor's I2C bus number
    BUS_NUMBER=$(${pkgs.ddcutil}/bin/ddcutil detect | grep -B 4 "P40w-20" | grep "I2C bus:" | sed -E 's/.*\/dev\/i2c-([0-9]+).*/\1/')

    if [ -z "$BUS_NUMBER" ]; then
      echo "Could not determine I2C bus for ThinkVision P40w-20. No action taken."
      exit 1
    fi

    echo "Found ThinkVision P40w-20 on bus $BUS_NUMBER"

    # Get the current input source
    CURRENT_INPUT=$(${pkgs.ddcutil}/bin/ddcutil --bus $BUS_NUMBER getvcp 60 | grep -o "sl=0x[0-9a-f]\+" | cut -d'x' -f2)

    # Strip 0x prefix if present
    CURRENT_INPUT=''${CURRENT_INPUT#0x}

    # Convert to lowercase for comparison
    CURRENT_INPUT=$(echo "$CURRENT_INPUT" | tr '[:upper:]' '[:lower:]')

    # Toggle between inputs 0f and 31
    if [ "$CURRENT_INPUT" = "0f" ] || [ "$CURRENT_INPUT" = "f" ]; then
      echo "Switching ThinkVision P40w-20 to input 0x31"
      ${pkgs.ddcutil}/bin/ddcutil --bus $BUS_NUMBER setvcp 60 0x31
    elif [ "$CURRENT_INPUT" = "31" ]; then
      echo "Switching ThinkVision P40w-20 to DisplayPort-1 (0x0F)"
      ${pkgs.ddcutil}/bin/ddcutil --bus $BUS_NUMBER setvcp 60 0x0f
    fi
  '';

  adjust-window-sizes = pkgs.writeShellScript "niri-adjust-window-sizes" ''
    # Track previous state to avoid unnecessary resizing
    last_workspace_id=""
    last_window_count=0

    niri msg --json event-stream | while read -r event; do
      # Check for window open/change or close events
      if echo "$event" | ${jq} -e '.WindowOpenedOrChanged or .WindowClosed' > /dev/null 2>&1; then
        sleep 0.05  # Reduced delay

        # Get the focused workspace ID
        focused_workspace_id=$(${niri} msg --json workspaces | ${jq} -r '.[] | select(.is_focused == true) | .id')

        # Count windows only on the focused workspace
        window_count=$(${niri} msg --json windows | $${jq} --argjson ws_id "$focused_workspace_id" '[.[] | select(.workspace_id == $ws_id and .is_floating == false)] | length')

        # Skip if nothing changed
        if [ "$focused_workspace_id" = "$last_workspace_id" ] && [ "$window_count" -eq "$last_window_count" ]; then
            continue
        fi

        echo "Workspace $focused_workspace_id has $window_count windows"

        # Resize logic
        if [ "$window_count" -eq 1 ]; then
          echo "Setting single window to 100%"
          ${niri} msg action set-column-width "100%"
        elif [ "$window_count" -ge 2 ]; then
          echo "Setting $window_count windows to 50%"
          # Only resize if we actually need to change something
          current_focused_column=$(niri msg --json windows | $${jq} --argjson ws_id "$focused_workspace_id" -r '[.[] | select(.workspace_id == $ws_id and .is_floating == false and .is_focused == true)][0] | .layout.pos_in_scrolling_layout[0]')

          # Go to first column
          ${niri} msg action focus-column-first

          # Set each column to 50%
          for i in $(seq 1 "$window_count"); do
            ${niri} msg action set-column-width "50%"
            if [ "$i" -lt "$window_count" ]; then
              ${niri} msg action focus-column-right
            fi
          done

          # Return focus to the originally focused column
          if [ -n "$current_focused_column" ] && [ "$current_focused_column" -gt 1 ]; then
            ${niri} msg action focus-column-first
            for j in $(seq 2 "$current_focused_column"); do
              ${niri} msg action focus-column-right
            done
          fi
        fi

        # Update state tracking
        last_workspace_id="$focused_workspace_id"
        last_window_count="$window_count"
      fi
    done
  '';
in
{
  imports = [
    ./waybar.nix
    # ./caelestia-shell.nix
    ./rofi.nix
    ./hyprlock.nix
    ./wlsunset.nix

    ./sway-idle.nix
    # ./hypridle.nix

    ## These services have problems when started from systemd
    ## Doesn't work with clipboard
    # ./flameshot.nix
  ];

  home.packages = with pkgs; [
    zenity
    imv
    i3status
    fuzzel
    wl-clipboard
    wdisplays
    wlr-randr

    nag-graphical
  ];

  xdg.configFile."hypr/hyprpaper.conf".text = lib.mkIf (osConfig.hostParams.desktop.wallpaper != null) ''
    splash = false
    preload = ${osConfig.hostParams.desktop.wallpaper}
    # Note the comma below. Put a monitor name before it to display wallpaper on a specific screen
    wallpaper = ,${osConfig.hostParams.desktop.wallpaper}
  '';

  programs.niriswitcher = {
    enable = true;
  };

  xdg.configFile."niri/config.kdl".text = ''
    // This config is in the KDL format: https://kdl.dev
    // "/-" comments out the following node.
    // Check the wiki for a full description of the configuration:
    // https://yalter.github.io/niri/Configuration:-Introduction

    // Input device configuration.
    // Find the full list of options on the wiki:
    // https://yalter.github.io/niri/Configuration:-Input
    input {
        keyboard {
            xkb {
                // You can set rules, model, layout, variant and options.
                // For more information, see xkeyboard-config(7).

                // For example:
                // layout "us,ru"
                // options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"

                // If this section is empty, niri will fetch xkb settings
                // from org.freedesktop.locale1. You can control these using
                // localectl set-x11-keymap.

                // Map Caps Lock to Escape
                options "caps:escape"

                // Or to disable Caps Lock entirely:
                // options "caps:off"
            }

            repeat-delay 255
            repeat-rate 50

            // Enable numlock on startup, omitting this setting disables it.
            numlock
        }

        // Next sections include libinput settings.
        // Omitting settings disables them, or leaves them at their default values.
        // All commented-out settings here are examples, not defaults.
        touchpad {
            // off
            // tap
            click-method "clickfinger"
            dwt  // disable when typing
            dwtp // disable when trackpading
            // drag false
            // drag-lock
            // natural-scroll
            // accel-speed 0.2
            // accel-profile "flat"
            // scroll-method "two-finger"
            // disabled-on-external-mouse
        }

        mouse {
            // off
            // natural-scroll
            // accel-speed 0.2
            // accel-profile "flat"
            // scroll-method "no-scroll"
        }

        trackpoint {
            // off
            // natural-scroll
            // accel-speed 0.2
            // accel-profile "flat"
            scroll-method "on-button-down"
            // scroll-button 273
            // scroll-button-lock
            // middle-emulation
        }

        // Uncomment this to make the mouse warp to the center of newly focused windows.
        // warp-mouse-to-focus

        // Focus windows and outputs automatically when moving the mouse into them.
        // Setting max-scroll-amount="0%" makes it work only on windows already fully on screen.
        // focus-follows-mouse max-scroll-amount="0%"
    }

    clipboard {
        // Prevent trackpad middle-click from pasting inadvertantly
        disable-primary
    }

    cursor {
        xcursor-theme "Bibata-Modern-Classic"
        xcursor-size 16
    }

    gestures {
        hot-corners {
            off
        }
    }

    // You can configure outputs by their name, which you can find
    // by running `niri msg outputs` while inside a niri instance.
    // The built-in laptop monitor is usually called "eDP-1".
    // Find more information on the wiki:
    // https://yalter.github.io/niri/Configuration:-Outputs
    // Remember
        // repeat-delay 600
        // repeat-rate 25 to uncomment the node by removing "/-"!
    /-output "eDP-1" {
        // Uncomment this line to disable this output.
        // off

        // Resolution and, optionally, refresh rate of the output.
        // The format is "<width>x<height>" or "<width>x<height>@<refresh rate>".
        // If the refresh rate is omitted, niri will pick the highest refresh rate
        // for the resolution.
        // If the mode is omitted altogether or is invalid, niri will pick one automatically.
        // Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
        mode "1920x1080@120.030"

        // You can use integer or fractional scale, for example use 1.5 for 150% scale.
        scale 2

        // Transform allows to rotate the output counter-clockwise, valid values are:
        // normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
        transform "normal"

        // Position of the output in the global coordinate space.
        // This affects directional monitor actions like "focus-monitor-left", and cursor movement.
        // The cursor can only move between directly adjacent outputs.
        // Output scale and rotation has to be taken into account for positioning:
        // outputs are sized in logical, or scaled, pixels.
        // For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080,
        // so to put another output directly adjacent to it on the right, set its x to 1920.
        // If the position is unset or results in an overlap, the output is instead placed
        // automatically.
        position x=1280 y=0
    }

    // Settings that influence how windows are positioned and sized.
    // Find more information on the wiki:
    // https://yalter.github.io/niri/Configuration:-Layout
    layout {
        always-center-single-column

        // Set gaps around windows in logical pixels.
        gaps 0

        // When to center a column when changing focus, options are:
        // - "never", default behavior, focusing an off-screen column will keep at the left
        //   or right edge of the screen.
        // - "always", the focused column will always be centered.
        // - "on-overflow", focusing a column will center it if it doesn't fit
        //   together with the previously focused column.
        center-focused-column "on-overflow"

        // You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
        preset-column-widths {
            // Proportion sets the width as a fraction of the output width, taking gaps into account.
            // For example, you can perfectly fit four windows sized "proportion 0.25" on an output.
            // The default preset widths are 1/3, 1/2 and 2/3 of the output.
            proportion 1.0
            // proportion 0.33333
            proportion 0.5
            // proportion 0.66667

            // Fixed sets the width in logical pixels exactly.
            // fixed 1920
        }

        // You can also customize the heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
        preset-window-heights {
            proportion 1.0
            proportion 0.5
        }

        // You can change the default width of the new windows.
        // default-column-width { proportion 0.5; }
        default-column-width { proportion 1.0; }
        // If you leave the brackets empty, the windows themselves will decide their initial width.
        // default-column-width {}

        // By default focus ring and border are rendered as a solid background rectangle
        // behind windows. That is, they will show up through semitransparent windows.
        // This is because windows using client-side decorations can have an arbitrary shape.
        //
        // If you don't like that, you should uncomment `prefer-no-csd` below.
        // Niri will draw focus ring and border *around* windows that agree to omit their
        // client-side decorations.
        //
        // Alternatively, you can override it with a window rule called
        // `draw-border-with-background`.

        // You can change how the focus ring looks.
        focus-ring {
            // Uncomment this line to disable the focus ring.
            // off

            // How many logical pixels the ring extends out from the windows.
            width 2

            // Colors can be set in a variety of ways:
            // - CSS named colors: "red"
            // - RGB hex: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
            // - CSS-like notation: "rgb(255, 127, 0)", rgba(), hsl() and a few others.

            // Color of the ring on the active monitor.
            active-color "#7fc8ff"

            // Color of the ring on inactive monitors.
            //
            // The focus ring only draws around the active window, so the only place
            // where you can see its inactive-color is on other monitors.
            inactive-color "#505050"

            // You can also use gradients. They take precedence over solid colors.
            // Gradients are rendered the same as CSS linear-gradient(angle, from, to).
            // The angle is the same as in linear-gradient, and is optional,
            // defaulting to 180 (top-to-bottom gradient).
            // You can use any CSS linear-gradient tool on the web to set these up.
            // Changing the color space is also supported, check the wiki for more info.
            //
            // active-gradient from="#80c8ff" to="#c7ff7f" angle=45

            // You can also color the gradient relative to the entire view
            // of the workspace, rather than relative to just the window itself.
            // To do that, set relative-to="workspace-view".
            //
            // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        }

        // You can also add a border. It's similar to the focus ring, but always visible.
        border {
            // The settings are the same as for the focus ring.
            // If you enable the border, you probably want to disable the focus ring.
            off

            width 2
            active-color "#ffc87f"
            inactive-color "#505050"

            // Color of the border around windows that request your attention.
            urgent-color "#9b0000"

            // Gradients can use a few different interpolation color spaces.
            // For example, this is a pastel rainbow gradient via in="oklch longer hue".
            //
            // active-gradient from="#e5989b" to="#ffb4a2" angle=45 relative-to="workspace-view" in="oklch longer hue"

            // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        }

        // You can enable drop shadows for windows.
        shadow {
            // Uncomment the next line to enable shadows.
            // on

            // By default, the shadow draws only around its window, and not behind it.
            // Uncomment this setting to make the shadow draw behind its window.
            //
            // Note that niri has no way of knowing about the CSD window corner
            // radius. It has to assume that windows have square corners, leading to
            // shadow artifacts inside the CSD rounded corners. This setting fixes
            // those artifacts.
            //
            // However, instead you may want to set prefer-no-csd and/or
            // geometry-corner-radius. Then, niri will know the corner radius and
            // draw the shadow correctly, without having to draw it behind the
            // window. These will also remove client-side shadows if the window
            // draws any.
            //
            // draw-behind-window true

            // You can change how shadows look. The values below are in logical
            // pixels and match the CSS box-shadow properties.

            // Softness controls the shadow blur radius.
            softness 30

            // Spread expands the shadow.
            spread 5

            // Offset moves the shadow relative to the window.
            offset x=0 y=5

            // You can also change the shadow color and opacity.
            color "#0007"
        }

        // Struts shrink the area occupied by windows, similarly to layer-shell panels.
        // You can think of them as a kind of outer gaps. They are set in logical pixels.
        // Left and right struts will cause the next window to the side to always be visible.
        // Top and bottom struts will simply add outer gaps in addition to the area occupied by
        // layer-shell panels and regular gaps.
        struts {
            // left 64
            // right 64

            // fixes focus-border visibility
            // @TODO: probably not right approach though
            top 2
            bottom 3
        }

        tab-indicator {
            // off
            // hide-when-single-tab
            place-within-column
            gap 0
            width 24
            length total-proportion=1.0
            position "top"
            gaps-between-tabs 0
            corner-radius 0
            active-color "#4488ff"
            inactive-color "gray"
            urgent-color "red"
            // active-gradient from="#80c8ff" to="#bbddff" angle=45
            // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
            // urgent-gradient from="#800" to="#a33" angle=45
        }
    }

    switch-events {
        lid-close { spawn "${hyprlockCommand}" "suspend"; }
    }

    // Add lines like this to spawn processes at startup.
    // Note that running niri as a session supports xdg-desktop-autostart,
    // which may be more convenient to use.
    // See the binds section below for more spawn examples.

    spawn-sh-at-startup "systemctl --user restart waybar"
    spawn-sh-at-startup "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    spawn-sh-at-startup "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    spawn-sh-at-startup "systemctl --user restart polkit-gnome-authentication-agent-1"

    // This line starts waybar, a commonly used bar for Wayland compositors.
    // Currently using systemd service
    spawn-sh-at-startup "systemctl --user restart kanshi"
    // spawn-sh-at-startup "${adjust-window-sizes}"

    spawn-sh-at-startup "${dynamic-float-rules}/bin/dynamic-float-rules"
    spawn-sh-at-startup "systemctl --user stop hypridle"
    spawn-sh-at-startup "pkill hyprlock"
    spawn-sh-at-startup "systemctl --user restart sway-idle"
    spawn-sh-at-startup "systemctl --user stop xdg-desktop-portal-wlr"
    spawn-sh-at-startup "systemctl --user stop xdg-desktop-portal-hyprland"
    spawn-sh-at-startup "systemctl --user restart xdg-desktop-portal-gnome"
    spawn-sh-at-startup "systemctl --user restart xdg-desktop-portal-gtk"
    spawn-sh-at-startup "systemctl --user restart wlsunset"
    spawn-sh-at-startup "systemctl --user restart swaynotificationcenter"
    spawn-sh-at-startup "systemctl --user restart network-manager-applet"
    spawn-sh-at-startup "systemctl --user restart blueman-applet"

    // To run a shell command (with variables, pipes, etc.), use spawn-sh-at-startup: // spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"
    hotkey-overlay {
        // Uncomment this line to disable the "Important Hotkeys" pop-up at startup.
        skip-at-startup
    }

    // Uncomment this line to ask the clients to omit their client-side decorations if possible.
    // If the client will specifically ask for CSD, the request will be honored.
    // Additionally, clients will be informed that they are tiled, removing some client-side rounded corners.
    // This option will also fix border/focus ring drawing behind some semitransparent windows.
    // After enabling or disabling this, you need to restart the apps for this to take effect.
    prefer-no-csd

    // You can change the path where screenshots are saved.
    // A ~ at the front will be expanded to the home directory.
    // The path is formatted with strftime(3) to give you the screenshot date and time.
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // You can also set this to null to disable saving screenshots to disk.
    // screenshot-path null

    // Animation settings.
    // The wiki explains how to configure individual animations:
    // https://yalter.github.io/niri/Configuration:-Animations
    animations {
        // Uncomment to turn off all animations.
        // off

        // Slow down all animations by this factor. Values below 1 speed them up instead.
        // slowdown 3.0
    }

    // Window rules let you adjust behavior for individual windows.
    // Find more information on the wiki:
    // https://yalter.github.io/niri/Configuration:-Window-Rules

    // Work around WezTerm's initial configure bug
    // by setting an empty default-column-width.
    window-rule {
        // This regular expression is intentionally made as specific as possible,
        // since this is the default config, and we want no false positives.
        // You can get away with just app-id="wezterm" if you want.
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }

    // Open the Firefox picture-in-picture player as floating by default.
    window-rule {
        // This app-id regular expression will work for both:
        // - host Firefox (app-id is "firefox")
        // - Flatpak Firefox (app-id is "org.mozilla.firefox")
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }

    window-rule {
        // match app-id=r#"Rofi$"# title="^rofi - Audio Sink$"
        match app-id=r#"Rofi$"#
        open-floating true
    }

    window-rule {
        match app-id=r#".blueman-manager-wrapped$"#
        open-floating true
    }

    window-rule {
        match app-id=r#"firefox$"# title="^Extension.*Mozilla Firefox$"
        open-floating true
    }

    window-rule {
        match app-id=r#".*-nngceckbapebfimnlniiiahkandclblb-Default$"#
        open-floating true
    }

    // Float any windows without app and title (e.g. chromium notifications)
    window-rule {
        match app-id=r#"^$"# title="^$"
        open-floating true
    }

    window-rule {
        match app-id=r#"^org\.gnome\.Calculator$"# title="^Calculator$"
        open-floating true
        default-column-width { fixed 702; }
        default-window-height { fixed 616; }
    }

    window-rule {
        match title="^(Open File|Save As|Open Folder|Open Workspace.*|Save Workspace.*|Add Folder.*|Save File|Print|Send by Email|Export Image.*)$"
        open-floating true
        default-column-width { fixed 1000; }
        default-window-height { fixed 800; }
    }

    // window-rule {
    //   match app-id="mpv"
    //   inhibit-idle true
    // }

    window-rule {
        match app-id="chromium-browser$"
        open-on-workspace "1"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="org.chromium.Chromium$"
        open-on-workspace "1"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="kitty$"
        open-on-workspace "2"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="foot$"
        open-on-workspace "2"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="Slack$"
        open-on-workspace "3"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="spotify$"
        open-on-workspace "4"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="brave-browser$"
        open-on-workspace "4"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="firefox$"
        open-on-workspace "5"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="signal$"
        open-on-workspace "6"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="org.telegram.desktop$"
        open-on-workspace "6"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="discord$"
        open-on-workspace "7"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="vesktop$"
        open-on-workspace "7"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="Element$"
        open-on-workspace "7"
        default-column-width { proportion 1.0; }
    }
    window-rule {
        match app-id="@joplin/app-desktop$"
        open-on-workspace "9"
        default-column-width { proportion 1.0; }
    }

    // Example: block out two password managers from screen capture.
    // (This example rule is commented out with a "/-" in front.)
    /-window-rule {
        match app-id=r#"^org\.keepassxc\.KeePassXC$"#
        match app-id=r#"^org\.gnome\.World\.Secrets$"#

        block-out-from "screen-capture"

        // Use this instead if you want them visible on third-party screenshot tools.
        // block-out-from "screencast"
    }

    // Example: enable rounded corners for all windows.
    // (This example rule is commented out with a "/-" in front.)
    /-window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    binds {
        // Keys consist of modifiers separated by + signs, followed by an XKB key name
        // in the end. To find an XKB name for a particular key, you may use a program
        // like wev.
        //
        // "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
        // when running as a winit window.
        //
        // Most actions that you can bind here can also be invoked programmatically with
        // `niri msg action do-something`.

        // Prevent errant middle-click paste
        MouseMiddle { spawn "true"; }

        // Mod-Shift-/, which is usually the same as Mod-?,
        // shows a list of important hotkeys.
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Suggested binds for running programs: terminal, app launcher, screen locker.
        Mod+Return hotkey-overlay-title="Open a Terminal: foot" { spawn "foot"; }
        // Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }
        Mod+P hotkey-overlay-title="Run an Application: rofi" { spawn ${rofi}; }
        // Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }
        Mod+X hotkey-overlay-title="Lock the Screen: hyprlock" allow-when-locked=true { spawn "${hyprlockCommand}"; }
        Mod+E hotkey-overlay-title="Toggle fcitx5 daemon" { spawn "${toggle-fcitx}"; }
        Mod+Y hotkey-overlay-title="Run Kanshi" allow-when-locked=true { spawn "systemctl" "--user" "restart" "kanshi"; }

        Mod+G hotkey-overlay-title="Switch ThinkVision Monitor Input" allow-when-locked=true { spawn "${toggle-thinkvision-input}"; }

        // Use spawn to run a shell command. Do this if you need pipes, multiple commands, etc.
        // Note: the entire command goes as a single argument. It's passed verbatim to `sh -c`.
        // For example, this is a standard bind to toggle the screen reader (orca).
        Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn "pkill" "orca" "||" "exec" "orca"; }

        // Example volume keys mappings for PipeWire & WirePlumber.
        // The allow-when-locked=true property makes them work even when the session is locked.
        // Using spawn allows to pass multiple arguments together with the command.
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
        XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

        // Example brightness key mappings for brightnessctl.
        // You can use regular spawn with multiple arguments too (to avoid going through "sh"),
        // but you need to manually put each argument in separate "" quotes.
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+11%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        // Open/close the Overview: a zoomed-out view of workspaces and windows.
        // You can also move the mouse into the top-left hot corner,
        // or do a four-finger swipe up on a touchpad.
        Mod+O repeat=false { toggle-overview; }

        // Mod+C repeat=false { close-window; }
        Mod+C repeat=false hotkey-overlay-title="Close focused window" { spawn "${kill-active}"; }
        Mod+Shift+C repeat=false hotkey-overlay-title="Force Close focused window" { spawn "${kill-active-force}"; }

        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H     { spawn "${focus-with-overview}" "focus-column-or-monitor-left" "true"; }
        Mod+L     { spawn "${focus-with-overview}" "focus-column-or-monitor-right" "true"; }
        Mod+Ctrl+H     { move-column-left-or-to-monitor-left; }
        Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
        Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }
        Mod+Ctrl+L     { move-column-right-or-to-monitor-right; }

        Mod+Shift+H     { focus-monitor-left; }
        Mod+Shift+J     { move-window-down-or-to-workspace-down; }
        Mod+Shift+K     { move-window-up-or-to-workspace-up; }
        Mod+Shift+L     { move-column-right-or-to-monitor-right; }

        // Alternative commands that move across workspaces when reaching
        // the first or last window in a column.
        Mod+J     { spawn "${focus-with-overview}" "focus-workspace-down"; }
        Mod+K     { spawn "${focus-with-overview}" "focus-workspace-up"; }
        // Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
        // Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

        Mod+Home { focus-column-first; }
        Mod+End  { focus-column-last; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End  { move-column-to-last; }

        Mod+Shift+Left  { focus-monitor-left; }
        Mod+Shift+Down  { focus-monitor-down; }
        Mod+Shift+Up    { focus-monitor-up; }
        Mod+Shift+Right { focus-monitor-right; }

        Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
        Mod+Shift+Ctrl+Down  { move-workspace-to-monitor-down; }
        Mod+Shift+Ctrl+Up    { move-workspace-to-monitor-up; }
        Mod+Shift+Ctrl+Right { move-workspace-to-monitor-right; }
        Mod+Shift+Ctrl+H     { move-workspace-to-monitor-left; }
        Mod+Shift+Ctrl+J     { move-workspace-to-monitor-down; }
        Mod+Shift+Ctrl+K     { move-workspace-to-monitor-up; }
        Mod+Shift+Ctrl+L     { move-workspace-to-monitor-right; }

        // Alternatively, there are commands to move just a single window:
        // Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
        // ...

        // And you can also move a whole workspace to another monitor:
        // Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
        // ...

        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
        Mod+Ctrl+U         { move-column-to-workspace-down; }
        Mod+Ctrl+I         { move-column-to-workspace-up; }

        // Alternatively, there are commands to move just a single window:
        // Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
        // ...

        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up   { move-workspace-up; }
        Mod+Shift+U         { move-workspace-down; }
        Mod+Shift+I         { move-workspace-up; }

        // You can bind mouse wheel scroll ticks using the following syntax.
        // These binds will change direction based on the natural-scroll setting.
        //
        // To avoid scrolling through workspaces really fast, you can use
        // the cooldown-ms property. The bind will be rate-limited to this value.
        // You can set a cooldown on any bind, but it's most useful for the wheel.
        Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

        Mod+WheelScrollRight      { focus-column-right; }
        Mod+WheelScrollLeft       { focus-column-left; }
        Mod+Ctrl+WheelScrollRight { move-column-right; }
        Mod+Ctrl+WheelScrollLeft  { move-column-left; }

        // Usually scrolling up and down with Shift in applications results in
        // horizontal scrolling; these binds replicate that.
        Mod+Shift+WheelScrollDown      { focus-column-right; }
        Mod+Shift+WheelScrollUp        { focus-column-left; }
        Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
        Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

        Ctrl+Shift+3 hotkey-overlay-title="Catpure Active Screen" { spawn "${capture-screen}" ; }
        Ctrl+Shift+4 hotkey-overlay-title="Catpure Selection" { spawn "${capture-selection}" ; }
        Ctrl+Shift+5 hotkey-overlay-title="Catpure Active Window" { spawn "${capture-window}" ; }

        // Similarly, you can bind touchpad scroll "ticks".
        // Touchpad scrolling is continuous, so for these binds it is split into
        // discrete intervals.
        // These binds are also affected by touchpad's natural-scroll, so these
        // example binds are "inverted", since we have natural-scroll enabled for
        // touchpads by default.
        // Mod+TouchpadScrollDown { spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+"; }
        // Mod+TouchpadScrollUp   { spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-"; }

        // You can refer to workspaces by index. However, keep in mind that
        // niri is a dynamic workspace system, so these commands are kind of
        // "best effort". Trying to refer to a workspace index bigger than
        // the current workspace count will instead refer to the bottommost
        // (empty) workspace.
        //
        // For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
        // will all refer to the 3rd workspace.
        Mod+1 { focus-workspace "1"; }
        Mod+2 { focus-workspace "2"; }
        Mod+3 { focus-workspace "3"; }
        Mod+4 { focus-workspace "4"; }
        Mod+5 { focus-workspace "5"; }
        Mod+6 { focus-workspace "6"; }
        Mod+7 { focus-workspace "7"; }
        Mod+8 { focus-workspace "8"; }
        Mod+9 { focus-workspace "9"; }
        Mod+0 { focus-workspace "0"; }
        Mod+Ctrl+1 { move-column-to-workspace "1"; }
        Mod+Ctrl+2 { move-column-to-workspace "2"; }
        Mod+Ctrl+3 { move-column-to-workspace "3"; }
        Mod+Ctrl+4 { move-column-to-workspace "4"; }
        Mod+Ctrl+5 { move-column-to-workspace "5"; }
        Mod+Ctrl+6 { move-column-to-workspace "6"; }
        Mod+Ctrl+7 { move-column-to-workspace "7"; }
        Mod+Ctrl+8 { move-column-to-workspace "8"; }
        Mod+Ctrl+9 { move-column-to-workspace "9"; }
        Mod+Ctrl+0 { move-column-to-workspace "0"; }

        // Alternatively, there are commands to move just a single window:
        // Mod+Ctrl+1 { move-window-to-workspace 1; }

        // Switches focus between the current and the previous workspace.
        // Mod+Tab { focus-workspace-previous; }

        // The following binds move the focused window in and out of a column.
        // If the window is alone, they will consume it into the nearby column to the side.
        // If the window is already in a column, they will expel it out.
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

        // Consume one window from the right to the bottom of the focused column.
        Mod+Comma  { consume-window-into-column; }
        // Expel the bottom window from the focused column to the right.
        Mod+Period { expel-window-from-column; }

        Mod+R { switch-preset-column-width; }
        // Cycling through the presets in reverse order is also possible.
        // Mod+R { switch-preset-column-width-back; }
        Mod+I { switch-preset-window-height-back; }
        Mod+Ctrl+R { reset-window-height; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Expand the focused column to space not taken up by other fully visible columns.
        // Makes the column "fill the rest of the space".
        Mod+Ctrl+F { expand-column-to-available-width; }

        Mod+M { center-column; }

        // Center all fully visible columns on screen.
        Mod+Ctrl+C { center-visible-columns; }

        // Finer width adjustments.
        // This command can also:
        // * set width in pixels: "1000"
        // * adjust width in pixels: "-5" or "+5"
        // * set width as a percentage of screen width: "25%"
        // * adjust width as a percentage of screen width: "-10%" or "+10%"
        // Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
        // set-column-width "100" will make the column occupy 200 physical screen pixels.
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }

        // Finer height adjustments when in column with other windows.
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // Move the focused window between the floating and the tiling layout.
        // Mod+V       { toggle-window-floating; }
        Mod+Space      { toggle-window-floating; }
        Mod+Shift+Space { switch-focus-between-floating-and-tiling; }

        // Toggle tabbed column display mode.
        // Windows in this column will appear as vertical tabs,
        // rather than stacked on top of each other.
        // Mod+T hotkey-overlay-title="Toggle tabs" { toggle-column-tabbed-display; }
        Mod+T hotkey-overlay-title="Toggle tabs" { spawn "${toggle-tabbed}"; }

        // Actions to switch layouts.
        // Note: if you uncomment these, make sure you do NOT have
        // a matching layout switch hotkey configured in xkb options above.
        // Having both at once on the same hotkey will break the switching,
        // since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
        // Mod+Space       { switch-layout "next"; }
        // Mod+Shift+Space { switch-layout "prev"; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        // Applications such as remote-desktop clients and software KVM switches may
        // request that niri stops processing the keyboard shortcuts defined here
        // so they may, for example, forward the key presses as-is to a remote machine.
        // It's a good idea to bind an escape hatch to toggle the inhibitor,
        // so a buggy application can't hold your session hostage.
        //
        // The allow-inhibiting=false property can be applied to other binds as well,
        // which ensures niri always processes them, even when an inhibitor is active.
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

        // The quit action will show a confirmation dialog to avoid accidental exits.
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+R { spawn "${reboot-dialog}"; }

        Mod+Shift+S { spawn "${suspend-dialog}"; }

        // Powers off the monitors. To turn them back on, do any input like
        // moving the mouse or pressing any other key.
        Mod+Shift+P { power-off-monitors; }

        Mod+N hotkey-overlay-title="Toggle notification list view" { spawn "${pkgs.swaynotificationcenter}/bin/swaync-client" "-t" "-sw"; }
        Mod+Shift+N hotkey-overlay-title="Clear notifications" { spawn "${pkgs.swaynotificationcenter}/bin/swaync-client" "-C" "-sw"; }
        Mod+Shift+Ctrl+N hotkey-overlay-title="Toggle notification do-not-disturb" { spawn "${pkgs.swaynotificationcenter}/bin/swaync-client" "-d" "-sw"; }

    }

    workspace "1" {
      open-on-output "eDP-1"
    }
    workspace "2" {
      open-on-output "eDP-1"
    }
    workspace "3" {
      open-on-output "eDP-1"
    }
    workspace "4" {
      open-on-output "eDP-1"
    }
    workspace "5" {
      open-on-output "eDP-1"
    }
    workspace "6" {
      open-on-output "eDP-1"
    }
    workspace "7" {
      open-on-output "eDP-1"
    }
    workspace "8" {
      open-on-output "eDP-1"
    }
    workspace "9" {
      open-on-output "eDP-1"
    }
    workspace "0" {
      open-on-output "eDP-1"
    }
  '';
}
