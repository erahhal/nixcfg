{ inputs, pkgs, launchAppsConfig, hostParams, ... }:

let
  rofi = "${pkgs.rofi-wayland}/bin/rofi -show drun -theme ~/.config/rofi/launcher.rasi";
  launcher = rofi;
  # lockCommand = pkgs.callPackage ../../pkgs/sway-lock-command { };
  lockCommand = pkgs.callPackage ../../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
  toggle-group = pkgs.writeShellScript "hyprland-toggle-group.sh" ''
    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
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
    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
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
    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
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
    if [ "$(${pkgs.hyprland}/bin/hyprctl activewindow -j | jq -r ".class")" = "Steam" ]; then
        ${pkgs.xdotool}/bin/xdotool getactivewindow windowunmap
    else
        ${pkgs.hyprland}/bin/hyprctl dispatch killactive ""
    fi
  '';
in
{
  imports = [
    ./swaynotificationcenter.nix
    ./network-manager-applet.nix
    ./rofi.nix
    # ./sway-idle.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./waybar.nix
    ./wlsunset.nix
  ];

  home.packages = with pkgs; [
    gnome3.zenity
    networkmanagerapplet
    imv
    i3status
    wl-clipboard
    gnome3.zenity
    wdisplays
    wlr-randr
    (
      pkgs.writeTextFile {
        name = "nag-graphical";
        destination = "/bin/nag-graphical";
        executable = true;
        text = ''
          #!/usr/bin/env bash

          # export GDK_DPI_SCALE=2
          if zenity --question --text="$1"; then
            $2
          fi
        '';
      }
    )
  ];

  xdg.configFile."hypr/hyprpaper.conf".text = if builtins.hasAttr "wallpaper" hostParams then ''
    preload = ${hostParams.wallpaper}
    wallpaper = ,${hostParams.wallpaper}
  '' else "";

  wayland.windowManager.hyprland = {
    enable = true;

    extraConfig = ''
      $mod = SUPER

      $term = ${pkgs.trunk.kitty}/bin/kitty

      # Set mouse cursor size
      exec-once=hyprctl setcursor Adwaita 24

      # Refresh services
      exec = ${pkgs.hyprpaper}/bin/hyprpaper
      exec = systemctl --user restart swaynotificationcenter
      exec = systemctl --user restart network-manager-applet
      exec = systemctl --user restart wlsunset
      # exec = systemctl --user restart sway-idle
      exec = systemctl --user restart hypridle
      exec = pkill waybar; sleep 1; ${pkgs.waybar}/bin/waybar
      exec = ${pkgs.blueman}/bin/blueman-applet
      exec = ${pkgs.fcitx5-with-addons}/bin/fcitx5 -d --replace
      exec = systemctl --user restart kanshi

      # @TODO
      # 1. Is this already being set?
      # 2. Is it being set BEFORE portals are executed?
      # SEE: https://wiki.hyprland.org/FAQ/#some-of-my-apps-take-a-really-long-time-to-open

      # exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      # exec-once = systemctl --user start clight

      # @TODO: Settings to not scale XWayland
      # xwayland {
      #   force_zero_scaling = true
      # }
      #
      # env = GDK_SCALE, 2
      # env = QT_SCALE_FACTOR, 1.6
      # env = XCURSOR_SIZE, 64

      env = XDG_CURRENT_DESKTOP, hyprland

      misc {
        # enable Variable Frame Rate
        # No longer an option?
        # @TODO: what has changed here?
        # no_vfr = 0

        # Don't show anime girl in background
        disable_hyprland_logo = true
        force_default_wallpaper = 0
        disable_splash_rendering = true

        # Screen sleep behavior
        # A bug makes these potentially eat up GPU
        # mouse_move_enables_dpms = true
        # key_press_enables_dpms = true

        mouse_move_focuses_monitor = false

        # jump to window that requests activation
        focus_on_activate = true
      }

      # touchpad gestures
      gestures {
        workspace_swipe = 1
        workspace_swipe_forever = 1
      }

      input {
        kb_layout = ro
        repeat_rate = 50
        repeat_delay = 255
        # Map caps to ctrl
        kb_options = ctrl:nocaps

        # Don't change focus on cursor move
        follow_mouse = 2

        # Don't automatically change focus between floating and tiled on mouse move
        float_switch_override_focus = 0

        # accel_profile = flat
        touchpad {
          scroll_factor = 0.3
          disable_while_typing = true
          tap-to-click = false
          # Don't use right side of pad as right click. two finger click is right click, three is middle
          clickfinger_behavior = true
        }
        accel_profile = adaptive
      }

      device {
        name = tpps/2-elan-trackpoint
        tap-to-click = false
        sensitivity = -0.3
      }

      general {
        # gaps_in = 5
        # gaps_out = 5
        gaps_in = 0
        gaps_out = 0
        border_size = 1
        resize_on_border = true
        no_border_on_floating = true
        col.active_border = rgba(4a7697ff)
        col.inactive_border = rgba(2b2b2bff)
      }

      decoration {
        # rounding = 8
        rounding = 0

        drop_shadow = 1
        shadow_ignore_window = 1
        shadow_offset = 2 2
        shadow_range = 4
        shadow_render_power = 1
        col.shadow = 0x55000000
      }

      animations {
        enabled = 0
        animation = border, 1, 2, default
        animation = fade, 1, 4, default
        animation = windows, 1, 3, default, popin 80%
        animation = workspaces, 1, 2, default, slide
      }

      dwindle {
        # keep floating dimentions while tiling
        pseudotile = 1
        preserve_split = 1
        # aka monocle mode
        no_gaps_when_only = 1
      }

      group {
        insert_after_current = false
        col.border_active = rgba(285577ff)
        col.border_inactive = rgba(2b2b2bff)
        groupbar {
          font_family = DejaVu Sans
          font_size = 18
          height = 18
          text_color = rgba(ffffffff)
          col.active = rgba(285577ff)
          col.inactive = rgba(2b2b2bff)
        }
      }

      windowrule = float, title:^(KCalc)$
      # Chrome Bitwarden popup
      # Firefox Bitwarden popup
      # title: Extension: (Bitwarden - Free Password Manager) - Bitwarden — Mozilla Firefox
      # @TODO: These don't work
      windowrulev2 = float, class:(firefox), title:(.*)(Extension)(.*)(Bitwarden)(.*)
      windowrulev2 = size, 400, 600, class:(firefox), title:(.*)(Extension)(.*)(Bitwarden)(.*)

      # telegram media viewer
      windowrule = float, title:^(Media viewer)$

      # make Firefox PiP window floating and sticky
      windowrule = float, title:^(Picture-in-Picture)$
      windowrule = pin, title:^(Picture-in-Picture)$

      # throw sharing indicators away
      windowrule = workspace special silent, title:^(Firefox — Sharing Indicator)$
      windowrule = workspace special silent, title:^(.*is sharing (your screen|a window)\.)$

      # idle inhibit while watching videos
      windowrule = idleinhibit focus, class:^(mpv)$
      windowrule = idleinhibit fullscreen, class:^(firefox)$
      # @TODO: Make sure class matches for these two
      windowrule = idleinhibit fullscreen, class:^(chromium)$
      windowrule = idleinhibit fullscreen, class:^(brave)$

      # mouse movements
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
      bindm = $mod_ALT, mouse:272, resizewindow
      # disable middle click paste
      bind = , mouse:274, exec, ;

      bind = $mod, Return, exec, $term
      bind = $mod, X, exec, ${lockCommand}
      # @TODO: Use the following instead: https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing
      bind = $mod, C, exec, ${kill-active}
      # bind = $mod, R, forcerendererreload
      bind = $mod, R, exec, hyprctl reload
      bind = $mod, Y, exec, systemctl --user restart kanshi
      bind = $mod, T, exec, ${toggle-group}
      bind = $mod_SHIFT, E, exec, nag-graphical 'Exit Hyprland?' 'pkill Hyprland'
      bind = $mod_SHIFT, P, exec, nag-graphical 'Power off?' 'systemctl poweroff -i, mode "default"'
      bind = $mod_SHIFT, R, exec, nag-graphical 'Reboot?' 'systemctl reboot'
      bind = $mod_SHIFT, S, exec, nag-graphical 'Suspend?' 'systemctl suspend'
      bind = $mod_SHIFT_CTRL, L, movecurrentworkspacetomonitor, r
      bind = $mod_SHIFT_CTRL, H, movecurrentworkspacetomonitor, l
      bind = $mod_SHIFT_CTRL, K, movecurrentworkspacetomonitor, u
      bind = $mod_SHIFT_CTRL, J, movecurrentworkspacetomonitor,

      bind = SHIFT_CTRL, 3, exec, ${pkgs.grim}/bin/grim -o $(${pkgs.hyprland}/bin/hyprctl -j activeworkspace | jq -r '.monitor') - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
      bind = SHIFT_CTRL, 4, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
      bind = SHIFT_CTRL, 5, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.hyprland}/bin/hyprctl -j activewindow | jq -r '.at | join(",")') $(${pkgs.hyprland}/bin/hyprctl -j activewindow | jq -r '.size | join("x")')" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png

      bind = $mod_CTRL, L, resizeactive, 10 0
      bind = $mod_CTRL, H, resizeactive, -10 0
      bind = $mod_CTRL, K, resizeactive, 0 -10
      bind = $mod_CTRL, J, resizeactive, 0 10

      # move focus
      # bind = $mod, H, movefocus, l
      bind = $mod, H, exec, ${move-left}
      # bind = $mod, L, movefocus, r
      bind = $mod, L, exec, ${move-right}
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d

      bind = $mod_SHIFT, L, movewindow, r
      bind = $mod_SHIFT, H, movewindow, l
      bind = $mod_SHIFT, K, movewindow, u
      bind = $mod_SHIFT, J, movewindow, d

      # workspaces
      # binds mod + [shift +] {1..10} to [move to] ws {1..10}
      ${builtins.concatStringsSep "\n" (builtins.genList (
          x: let
            ws = let
              c = (x + 1) / 10;
            in
              builtins.toString (x + 1 - (c * 10));
          in ''
            bind = $mod, ${ws}, workspace, ${toString (x + 1)}
            bind = $mod_SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
          ''
        )
        10)}

      bind = $mod, F, fullscreen
      bind = $mod, SPACE, togglefloating
      bind = $mod, P, exec, ${launcher}

      bind = $mod, Escape, exec, wlogout -p layer-shell

      # select area to perform OCR on
      bind = $mod, O, exec, run-as-service wl-ocr

      # window resize
      bind = $mod, S, submap, resize

      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset

      # media controls
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous
      bindl = , XF86AudioNext, exec, playerctl next

      # volume
      bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%+
      bindle = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%-
      bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # backlight
      bindle = , XF86MonBrightnessUp, exec, light -A 5
      bindle = , XF86MonBrightnessDown, exec, light -U 5

      # screenshot
      # stop animations while screenshotting; makes black border go away
      $screenshotarea = hyprctl keyword animation "fadeOut,0,0,default"; grimblast --notify copysave area; hyprctl keyword animation "fadeOut,1,4,default"
      bind = , Print, exec, $screenshotarea

      bind = CTRL, Print, exec, grimblast --notify --cursor copysave output
      bind = $mod_SHIFT_CTRL, R, exec, grimblast --notify --cursor copysave output

      bind = ALT, Print, exec, grimblast --notify --cursor copysave screen
      bind = $mod_SHIFT_ALT, R, exec, grimblast --notify --cursor copysave screen

      # special workspace
      bind = $mod_SHIFT, grave, movetoworkspace, special
      bind = $mod, grave, togglespecialworkspace, eDP-1

      # cycle workspaces
      bind = $mod, bracketleft, workspace, m-1
      bind = $mod, bracketright, workspace, m+1

      # cycle monitors
      bind = $mod_SHIFT, braceleft, focusmonitor, l
      bind = $mod_SHIFT, braceright, focusmonitor, r

      ${launchAppsConfig}
    '';
  };
}
