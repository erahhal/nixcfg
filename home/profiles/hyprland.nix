{ osConfig, lib, inputs, pkgs, ... }:

let
  terminal = "foot";
  # terminal = "kitty";
  # terminal = "ghostty";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  rofi = "${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/launcher.rasi";
  launcher = rofi;
  exit-hyprland = pkgs.writeShellScript "exit-hyprland" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    pkill Hyprland
  '';
  reboot = pkgs.writeShellScript "kill-reboot" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    systemctl reboot
  '';
  poweroff = pkgs.writeShellScript "kill-poweroff" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    systemctl poweroff
  '';

  xdg-desktop-portal-hyprland = pkgs.writeShellScript "xdg-desktop-portal-hyprland" ''
    sleep 1
    kill $(${pkgs.procps}/bin/pidof xdg-desktop-portal-hyprland)
    kill $(${pkgs.procps}/bin/pidof xdg-desktop-portal-wlr)
    kill $(${pkgs.procps}/bin/pidof xdg-desktop-portal)
    ${pkgs.unstable.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland &
    sleep 2
    ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal &
  '';

  nag-graphical = pkgs.callPackage ../../pkgs/nag-graphical {};

  wallpaper-cmd = if (osConfig.hostParams.desktop.wallpaper != null) then pkgs.writeShellScript "hyprland-wallpaper" ''
    killall hyprpaper
    killall mpvpaper
    killall swaybg
    # ${pkgs.swaybg}/bin/swaybg -i "$(${pkgs.findutils}/bin/find ~/.config/wallpapers/. -type f| ${pkgs.coreutils}/bin/shuf -n1)"
    # ${pkgs.swaybg}/bin/swaybg -i ${osConfig.hostParams.desktop.wallpaper} -m fill
    ${pkgs.hyprpaper}/bin/hyprpaper
  '' else "";

  ## This is fun, but eats up a ton of GPU
  wallpaper-animated = pkgs.writeShellScript "hyprland-wallpaper-animated" ''
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
  toggle-group = pkgs.writeShellScript "hyprland-toggle-group.sh" ''
    HYPRCTL=${hyprctl};
    JQ=${pkgs.jq}/bin/jq
    BASE64=${pkgs.coreutils}/bin/base64

    ACTIVEWORKSPACE=$($HYPRCTL -j activeworkspace | $JQ ".id")
    ACTIVEWORKSPACE_WINDOWS_JSON=$($HYPRCTL -j clients | $JQ "map_values(select(.workspace.id == $ACTIVEWORKSPACE)) | map({address,class,title,at})")

    INDEX=0
    for ROW in $(echo "$ACTIVEWORKSPACE_WINDOWS_JSON" | $JQ -r '.[] | @base64'); do
        WINDOW=$(echo $ROW | $BASE64 --decode)
        ADDRESS=$(echo $WINDOW | $JQ -r ".address")
        $HYPRCTL dispatch focuswindow address:$ADDRESS
        if [ "$INDEX" == "0" ]; then
            FIRST_WINDOW_X=$(echo $WINDOW | $JQ -r ".at[0]")
            FIRST_WINDOW_Y=$(echo $WINDOW | $JQ -r ".at[1]")
            $HYPRCTL dispatch togglegroup
        else
            WINDOW_X=$(echo $WINDOW | $JQ -r ".at[0]")
            WINDOW_Y=$(echo $WINDOW | $JQ -r ".at[1]")
            if [ "$FIRST_WINDOW_X" -gt "$WINDOW_X" ]; then
                DIRECTION=r
            elif [ "$FIRST_WINDOW_X" -lt "$WINDOW_X" ]; then
                DIRECTION=l
            elif [ "$FIRST_WINDOW_Y" -gt "$WINDOW_Y" ]; then
                DIRECTION=d
            else
                DIRECTION=u
            fi
            $HYPRCTL dispatch moveintogroup $DIRECTION
        fi
        INDEX=$((INDEX+1))
    done
  '';

  move-left = pkgs.writeShellScript "hyprland-move-left.sh" ''
    HYPRCTL=${hyprctl};
    JQ=${pkgs.jq}/bin/jq

    ACTIVEWINDOW=$($HYPRCTL -j activewindow | $JQ "{address,grouped}")
    ADDRESS=$(echo $ACTIVEWINDOW | $JQ -r ".address")
    GROUP_FIRST=$(echo $ACTIVEWINDOW | $JQ -r ".grouped[0]")
    if [ "$GROUP_FIRST" == "null" ] || [ "$ADDRESS" == "$GROUP_FIRST" ]; then
        $HYPRCTL dispatch movefocus l
    else
        $HYPRCTL dispatch changegroupactive b
    fi
  '';

  move-right = pkgs.writeShellScript "hyprland-move-right.sh" ''
    HYPRCTL=${hyprctl};
    JQ=${pkgs.jq}/bin/jq

    ACTIVEWINDOW=$($HYPRCTL -j activewindow | $JQ "{address,grouped}")
    ADDRESS=$(echo $ACTIVEWINDOW | $JQ -r ".address")
    GROUP_LAST=$(echo $ACTIVEWINDOW | $JQ -r ".grouped[-1]")
    if [ "$GROUP_LAST" == "null" ] ||  [ "$ADDRESS" == "$GROUP_LAST" ]; then
        $HYPRCTL dispatch movefocus r
    else
        $HYPRCTL dispatch changegroupactive f
    fi
  '';

  kill-active = pkgs.writeShellScript "hyprland-kill-active.sh" ''
    HYPRCTL=${hyprctl};
    if [ "$($HYPRCTL activewindow -j | jq -r ".class")" = "Steam" ]; then
        ${pkgs.xdotool}/bin/xdotool getactivewindow windowunmap
    elif [ "$($HYPRCTL activewindow -j | jq -r ".class")" =  "${terminal}" ]; then
        echo "Not closing."
        # address=$($HYPRCTL activewindow -j | jq -r ".address")
        # nag-graphical 'Exit Foot?' "$HYPRCTL dispatch closewindow address:$address" --default-cancel
    else
        $HYPRCTL dispatch killactive ""
    fi
  '';

  hyprland-bitwarden-resize = pkgs.writeShellScript "hyprland-bitwarden-resize" ''
    HYPRCTL=${hyprctl};
    handle() {
      case $1 in
        windowtitle*)
          # Extract the window ID from the line
          window_id=''${1#*>>}
          # Fetch the list of windows and parse it using jq to find the window by its decimal ID
          window_info=$($HYPRCTL clients -j | ${pkgs.jq}/bin/jq --arg id "0x$window_id" '.[] | select(.address == ($id))')
          # Extract the title from the window info
          window_title=$(echo "$window_info" | ${pkgs.jq}/bin/jq '.title')
          # Check if the title matches the characteristics of the Bitwarden popup window
          if [[ "$window_title" == *"Extension: (Bitwarden Password Manager) - Bitwarden — Mozilla Firefox"* ]]; then
            # echo $window_id, $window_title
            # Break out of tabbed group, make floating, resize and position
            $HYPRCTL --batch "dispatch moveoutofgroup address:0x$window_id ; dispatch togglefloating address:0x$window_id ; dispatch resizewindowpixel exact 20% 40%,address:0x$window_id ; dispatch movewindowpixel exact 40% 30%,address:0x$window_id"
          fi
          ;;
      esac
    }
    # Kill old process
    ${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep "[s]ocat" | ${pkgs.gnugrep}/bin/grep '[h]ypr' | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs kill
    # Listen to the Hyprland socket for events and process each line with the handle function
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
  '';

  # Create a script to toggle between inputs only on P40w-20 monitors
  toggle-input = pkgs.writeShellScript "toggle-input" ''
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
in
{
  imports = [
    ./waybar.nix
    # ./caelestia-shell.nix
    ./rofi.nix
    ./hyprlock.nix
    ./gammastep.nix
    # ./wlsunset.nix

    # ./sway-idle.nix
    ./hypridle.nix

    ## Doesn't work with clipboard
    # ./flameshot.nix
  ];

  home.packages = with pkgs; [
    zenity
    imv
    i3status
    wl-clipboard
    wdisplays
    wlr-randr

    nag-graphical
  ];

  # Not sure why max_fps is duplicated. Got this example from someone else
  # "allow_token_by_default" causes the share dialog checkbox to be "checked".
  # it's not visibly checked though. It's supposed to prevent the dialog
  # from popping up 3 times.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      allow_token_by_default = true
    }
  '';

  xdg.configFile."hypr/hyprpaper.conf".text = lib.mkIf (osConfig.hostParams.desktop.wallpaper != null) ''
    splash = false
    preload = ${osConfig.hostParams.desktop.wallpaper}
    # Note the comma below. Put a monitor name before it to display wallpaper on a specific screen
    wallpaper = ,${osConfig.hostParams.desktop.wallpaper}
  '';

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      debug = {
        disable_logs = false;
        # Temporary, to get rid of clean divisor error on 5k2k monitor
        # suppress_errors = true;
      };

      "$mod" = "SUPER";

      "$term" = "${pkgs.${terminal}}/bin/${terminal}";

      exec-once = [
        # Import all environment variables from the systemd user session
        "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all"
        # Update hyprland signature so hyprctl works with long-lived tmux sessions
        # Only works with new tmux panes, not existing ones
        ''tmux setenv -g HYPRLAND_INSTANCE_SIGNATURE "$HYPRLAND_INSTANCE_SIGNATURE"''
        # "${pkgs.fcitx5-with-addons}/bin/fcitx5 -d --replace"
        # "${pkgs.waybar}/bin/waybar"
        # "${pkgs.hyprpaper}/bin/hyprpaper"

        ## 1. This is already being set by home-manager
        ## SEE: https://wiki.hyprland.org/FAQ/#some-of-my-apps-take-a-really-long-time-to-open
        # "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

        # "systemctl --user start clight"
      ];

      # Refresh services and processes
      exec = [
        wallpaper-cmd
        ## Crashes Hyprland when used in a multi-monitor setup
        #"pkill flameshot; XDG_CURRENT_DESKTOP=sway ${pkgs.flameshot}/bin/flameshot"
        ## Running as a service doesn't wor with clipboard
        # "systemctl --user restart flameshot"
        "systemctl --user restart xdg-desktop-portal-hyprland"
        "systemctl --user restart polkit-gnome-authentication-agent-1"
        # "systemctl --user restart wlsunset"
        "systemctl --user restart gammastep"
        # "systemctl --user restart kanshi"
        ## Don't start on load - still causes issues with lost keystrokes
        # "systemctl --user restart fcitx5-daemon"
        ## hyprlock currently broken
        (
          if osConfig.hostParams.desktop.defaultLockProgram == "swaylock" then
            "systemctl --user stop hypridle"
          else
            "systemctl --user stop sway-idle"
        )
        (
          if osConfig.hostParams.desktop.defaultLockProgram == "swaylock" then
            "systemctl --user restart sway-idle"
          else
            "systemctl --user restart hypridle"
        )

        "systemctl --user restart waybar"
        ## Disabled as it doesn't work with tabbed groups
        hyprland-bitwarden-resize
      ];

      xwayland = {
        # Don't scale xwayland
        # In conjunction with Xft.dpi being set to something high, like 210
        force_zero_scaling = osConfig.hostParams.desktop.disableXwaylandScaling;
      };

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"

        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"

        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORMTHEME,qt6ct"
      ];

      misc = {

        ## Disable "Application is not responding" dialog
        enable_anr_dialog = false;

        vfr = true;

        # Don't show anime girl in background
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
        disable_splash_rendering = true;

        # Screen sleep behavior
        # A bug makes these potentially eat up GPU
        # mouse_move_enables_dpms = true;
        # key_press_enables_dpms = true;

        mouse_move_focuses_monitor = false;

        # jump to window that requests activation
        focus_on_activate = true;

        # Font family
        font_family = "DejaVu Sans";
      };

      # touchpad gestures
      gestures = {
        # workspace_swipe = 1;
        workspace_swipe_forever = 1;
      };

      input = {
        kb_layout = "us, cn";
        repeat_rate = 50;
        repeat_delay = 255;
        # Map caps to ctrl
        kb_options = "ctrl:nocaps";

        # Don't change focus on cursor move
        follow_mouse = 2;

        # Don't automatically change focus between floating and tiled on mouse move
        float_switch_override_focus = 0;

        # accel_profile = flat
        touchpad = {
          scroll_factor = 0.3;
          disable_while_typing = true;
          tap-to-click = false;
          # Don't use right side of pad as right click. two finger click is right click, three is middle
          clickfinger_behavior = true;
        };
        accel_profile = "adaptive";
      };

      # Thinkpad Trackpoint
      device = {
        name = "tpps/2-elan-trackpoint";
        tap-to-click = false;
        sensitivity = -0.3;
      };

      general = {
        # gaps_in = 5;
        # gaps_out = 5;
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        resize_on_border = true;
        extend_border_grab_area = 25;
        no_border_on_floating = true;
        "col.active_border" = "rgba(4a7697ff)";
        "col.inactive_border" = "rgba(2b2b2bff)";
      };

      decoration = {
        # rounding = 8;
        rounding = 0;

        shadow = {
          enabled = false;
        };

        blur = {
          enabled = false;
        };
      };

      dwindle = {
        # keep floating dimentions while tiling
        pseudotile = true;
        preserve_split = true;
      };

      layerrule = [
        # "blur, waybar"
      ];

      workspace = [
        # Don't show border for workspaces with a single tiled window
        "w[t1], border:false"
        # Don't show border for workspaces with a single grouped window
        "w[g1], border:false"
      ];

      windowrulev2 = [
        # Hack to workaround transparent border around floating windows
        # "opacity 0.999 0.999, floating:1"
        "opacity 0.999 0.999, class:^(.*)$"

        "float, title:^(Open File)$"
        "float, initialTitle:^(Open File)$"
        "float, title:^(Open Folder)$"
        "float, initialTitle:^(Open Folder)$"
        "float, title:^(Open Workspace.*)$"
        "float, initialTitle:^(Open Workspace.*)$"
        "float, title:^(Save Workspace.*)$"
        "float, initialTitle:^(Save Workspace.*)$"
        "float, title:^(Add Folder.*)$"
        "float, initialTitle:^(Add Folder.*)$"
        "float, title:^(Save As)$"
        "float, initialTitle:^(Save As)$"
        "float, title:^(Save File)$"
        "float, initialTitle:^(Save File)$"
        "float, title:^(Print)$"
        "float, initialTitle:^(Print)$"
        "float, title:^(Send by Email)$"
        "float, initialTitle:^(Send by Email)$"
        "float, title:^(Export Image.*)$"
        "float, initialTitle:^(Export Image.*)$"
        "float, title:^(KCalc)$"
        "float, class:^(org.gnome.Calculator)$"
        ## Windows without class float automatically
        "float, initialClass:^$"
        "float, class:^$"

        # telegram media viewer
        "float, title:^(Media viewer)$"

        # make Firefox PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # throw sharing indicators away
        "workspace special silent, title:^(Firefox — Sharing Indicator)$"
        "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

        # Modals
        "stayfocused, class:^(zenity)$"
        # "center, class:^(zenity)$"

        # idle inhibit while watching videos
        "float, initialClass:^(mpv)$"
        "float, class:^(mpv)$"
        "fullscreen, initialClass:^(mpv)$"
        "fullscreen, class:^(mpv)$"
        "fullscreen, initialClass:^(vimiv)$"
        "fullscreen, class:^(vimiv)$"
        "idleinhibit focus, initialClass:^(mpv)$"
        "idleinhibit focus, class:^(mpv)$"
        "idleinhibit focus, class:^(zoom)$"
        "idleinhibit fullscreen, class:^(firefox)$"

        # @TODO: Make sure class matches for these two
        "idleinhibit fullscreen, class:^(chromium)$"
        "idleinhibit fullscreen, class:^(brave)$"

        # Chrome Bitwarden popup
        # Firefox Bitwarden popup
        # title: Extension: (Bitwarden - Free Password Manager) - Bitwarden — Mozilla Firefox
        "float, initialTitle:^(Bitwarden)$"
        "float, title:^(Extension: .*)$"
        ## Chrome/Brave extension
        ## float is not dynamic so it matches initialTitle and not title
        ## See: https://github.com/hyprwm/Hyprland/issues/6302
        ## See: https://github.com/hyprwm/Hyprland/issues/3835
        "float, initialTitle:^(_crx_nngceckbapebfimnlniiiahkandclblb)$"
        "center, initialTitle:^(_crx_nngceckbapebfimnlniiiahkandclblb)$"
        "size 400 600, initialTitle:^(_crx_nngceckbapebfimnlniiiahkandclblb)$"
        ## Firefox Bitwarden
        "suppressevent maximize, class:^(firefox)$"

        # Flameshot
        ## important
        "fullscreen,class:flameshot"
        "float,class:flameshot"
        "monitor 0,class:flameshot"
        "move 0 0,class:flameshot"
        ## visual
        "noanim,class:flameshot"
        "noborder,class:flameshot"
        "rounding 0,class:flameshot"

        ## Orca slicer / Bambustudio fix
        ## See: https://github.com/hyprwm/Hyprland/issues/6698
        "stayfocused, class:^(BambuStudio)$,title:^()$"
        "suppressevent activate, class:^(BambuStudio)$,title:^()$"

        ## Fix issue with Jetbrains focus
        ## https://github.com/hyprwm/Hyprland/discussions/9866
        "noinitialfocus, class:(jetbrains-idea), title:^win(.*)"
        "noinitialfocus, class:(jetbrains-studio), title:^win(.*)"
      ];

      "$screenshotarea" = "${hyprctl} keyword animation \"fadeOut,0,0,default\"; grimblast --notify copysave area; ${hyprctl} keyword animation \"fadeOut,1,4,default\"";

      ## Bind Flags
      ## ----------
      ## l -> locked, will also work when an input inhibitor (e.g. a lockscreen) is active.
      ## r -> release, will trigger on release of a key.
      ## e -> repeat, will repeat when held.
      ## n -> non-consuming, key/mouse events will be passed to the active window in addition to triggering the dispatcher.
      ## m -> mouse, see below
      ## t -> transparent, cannot be shadowed by other binds.
      ## i -> ignore mods, will ignore modifiers.

      bind = [
        # Toggle FCITX service
        # Only really needed until the following bug is resolved:
        # https://github.com/hyprwm/Hyprland/issues/5815
        "$mod, E, exec, if systemctl --user is-active --quiet fcitx5-daemon; then systemctl --user stop fcitx5-daemon; else systemctl --user start fcitx5-daemon; fi"

        "$mod, Return, exec, $term"
        (
          if osConfig.hostParams.desktop.defaultLockProgram == "swaylock" then
            "$mod, X, exec, ${swayLockCommand}"
          else
            "$mod, X, exec, ${hyprlockCommand}"
        )
        # @TODO: Use the following instead: https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing
        "$mod, A, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a --format=hex"
        # Kill
        "$mod, C, exec, ${kill-active}"
        # Force kill
        "$mod_SHIFT, C, exec, ${hyprctl} -j activewindow | ${pkgs.jq}/bin/jq '.pid' | ${pkgs.findutils}/bin/xargs -L 1 kill -9"
        # "$mod, R, forcerendererreload"
        "$mod, R, exec, ${hyprctl} reload"
        "$mod, Y, exec, systemctl --user restart kanshi"
        "$mod, T, exec, ${toggle-group}"
        "$mod_SHIFT, E, exec, nag-graphical 'Exit Hyprland?' '${exit-hyprland}'"
        "$mod_SHIFT, P, exec, nag-graphical 'Power off?' '${poweroff}'"
        "$mod_SHIFT, R, exec, nag-graphical 'Reboot?' '${reboot}'"
        (
          if osConfig.hostParams.desktop.defaultLockProgram == "swaylock" then
            "$mod_SHIFT, S, exec, nag-graphical 'Suspend?' '${swayLockCommand} suspend'"
          else
            "$mod_SHIFT, S, exec, nag-graphical 'Suspend?' '${hyprlockCommand} suspend'"
        )
        "$mod_SHIFT_CTRL, L, movecurrentworkspacetomonitor, r"
        "$mod_SHIFT_CTRL, H, movecurrentworkspacetomonitor, l"
        "$mod_SHIFT_CTRL, K, movecurrentworkspacetomonitor, u"
        "$mod_SHIFT_CTRL, J, movecurrentworkspacetomonitor, d"

        ## Toggle notification list view
        "$mod, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"
        ## Clear notifications
        "$mod_SHIFT, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -C -sw"
        ## Toggle notification do-not-disturb
        "$mod_SHIFT_CTRL, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw"

        "$mod, G, exec, ${toggle-input}"

        ## @TODO: Replace with hyprshot
        "SHIFT_CTRL, 3, exec, ${pkgs.grim}/bin/grim -o $(${hyprctl} -j activeworkspace | jq -r '.monitor') - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png"
        "SHIFT_CTRL, 4, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp -d)\" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png"
        "SHIFT_CTRL, 5, exec, ${pkgs.grim}/bin/grim -g \"$(${hyprctl} -j activewindow | jq -r '.at | join(\",\")') $(${hyprctl} -j activewindow | jq -r '.size | join(\"x\")')\" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png"

        "$mod_CTRL, L, resizeactive, 10 0"
        "$mod_CTRL, H, resizeactive, -10 0"
        "$mod_CTRL, K, resizeactive, 0 -10"
        "$mod_CTRL, J, resizeactive, 0 10"

        # move focus
        # "$mod, H, movefocus, l"
        "$mod, H, exec, ${move-left}"
        # "$mod, L, movefocus, r"
        "$mod, L, exec, ${move-right}"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        "$mod_SHIFT, L, movewindow, r"
        "$mod_SHIFT, H, movewindow, l"
        "$mod_SHIFT, K, movewindow, u"
        "$mod_SHIFT, J, movewindow, d"

        "$mod, F, fullscreen"
        "$mod, SPACE, togglefloating"
        "$mod, P, exec, ${launcher}"

        "$mod, Escape, exec, wlogout -p layer-shell"

        # select area to perform OCR on
        "$mod, O, exec, run-as-service wl-ocr"

        # window resize
        # "$mod, S, submap, resize"

        # Pin window
        "$mod, S, pin"

        # screenshot
        # stop animations while screenshotting; makes black border go away
        ", Print, exec, $screenshotarea"

        "CTRL, Print, exec, grimblast --notify --cursor copysave output"
        "$mod_SHIFT_CTRL, R, exec, grimblast --notify --cursor copysave output"

        "ALT, Print, exec, grimblast --notify --cursor copysave screen"
        "$mod_SHIFT_ALT, R, exec, grimblast --notify --cursor copysave screen"

        # special workspace
        # "$mod_SHIFT, grave, movetoworkspace, special"
        # "$mod, grave, togglespecialworkspace, eDP-1"

        # cycle workspaces
        "$mod, bracketleft, workspace, m-1"
        "$mod, bracketright, workspace, m+1"

        # cycle monitors
        "$mod_SHIFT, braceleft, focusmonitor, l"
        "$mod_SHIFT, braceright, focusmonitor, r"

        # disable middle click paste
        ", mouse:274, exec, ;"
      ] ++ (
        # workspaces
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod_SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10)
      );

      # mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod_ALT, mouse:272, resizewindow"
      ];

      # locked binds (will also work when screen is locked)
      bindl = [
        # media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      # repeating and locked binds
      bindle = [
        # volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%-"

        # backlight
        ", XF86MonBrightnessUp, exec, light -A 5"
        ", XF86MonBrightnessDown, exec, light -U 5"
      ];
    };

    extraConfig = ''
      # repeating binds (will repeat when key is held)
      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset
    '';
  };
}
