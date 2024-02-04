{ pkgs, launchAppsConfig, hostParams, ... }:

let
  rofi = "${pkgs.rofi-wayland}/bin/rofi -show drun -theme ~/.config/rofi/launcher.rasi";
  wofi = "${pkgs.wofi}/bin/wofi --show run -W 400 -H 300";
  launcher = rofi;
  swayLockCmd = pkgs.callPackage ../../pkgs/sway-lock-command { };
  toggle-group = pkgs.writeShellScript "hyprland-toggle-group.sh" ''
    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
    JQ=${pkgs.jq}/bin/jq
    BASE64=${pkgs.coreutils}/bin/base64

    ACTIVEWORKSPACE=$($HYPRCTL -j activeworkspace | $JQ ".id")
    ACTIVEWORKSPACE_WINDOWS_JSON=$($HYPRCTL -j clients | $JQ "map_values(select(.workspace.id == $ACTIVEWORKSPACE)) | map({address,class,title,at})")

    INDEX=0
    for ROW in $(echo "$ACTIVEWORKSPACE_WINDOWS_JSON" | $JQ -r '.[] | @base64'); do
        WINDOW=$(echo $ROW | $BASE64 --decode)
        CLASS=$(echo $WINDOW | $JQ -r ".class")
        TITLE=$(echo $WINDOW | $JQ -r ".title")
        $HYPRCTL dispatch focuswindow "title:$TITLE"
        if [ "$INDEX" == "0" ]; then
            FIRST_WINDOW_X=$(echo $WINDOW | $JQ -r ".at[0]")
            $HYPRCTL dispatch togglegroup
        else
            WINDOW_X=$(echo $WINDOW | $JQ -r ".at[0]")
            if [ "$FIRST_WINDOW_X" -gt "$WINDOW_X" ]; then
                DIRECTION=r
            else
                DIRECTION=l
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

  move-right = pkgs.writeShellScript "hyprland-move-left.sh" ''
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
in
{
  imports = [
    ./swaynotificationcenter.nix
    ./network-manager-applet.nix
    ./rofi.nix
    ./sway-idle.nix
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

      ## Refresh services
      exec = ${pkgs.hyprpaper}/bin/hyprpaper
      exec = systemctl --user restart swaynotificationcenter
      exec = systemctl --user restart network-manager-applet
      exec = systemctl --user restart wlsunset
      exec = systemctl --user restart sway-idle
      exec = pkill waybar; ${pkgs.waybar}/bin/waybar
      exec = ${pkgs.blueman}/bin/blueman-applet
      exec = ${pkgs.fcitx5-with-addons}/bin/fcitx5 -d --replace
      exec = systemctl --user restart kanshi

      ## @TODO
      ## 1. Is this already being set?
      ## 2. Is it being set BEFORE portals are executed?
      ## SEE: https://wiki.hyprland.org/FAQ/#some-of-my-apps-take-a-really-long-time-to-open
      # exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      # exec-once = systemctl --user start clight

      ## @TODO: Settings to not scale XWayland
      # xwayland {
      #   force_zero_scaling = true
      # }
      #
      # env = GDK_SCALE, 2
      # env = QT_SCALE_FACTOR, 1.6
      # env = XCURSOR_SIZE, 64

      env = XDG_CURRENT_DESKTOP, hyprland

      misc {
        ## enable Variable Frame Rate
        ## No longer an option?
        ## @TODO: what has changed here?
        # no_vfr = 0
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

        # focus change on cursor move
        follow_mouse = 2
        # accel_profile = flat
        touchpad {
          scroll_factor = 0.3
        }
        accel_profile = adaptive
      }

      general {
        # gaps_in = 5
        # gaps_out = 5
        gaps_in = 0
        gaps_out = 0
        border_size = 1
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
          font_size = 14
          height = 18
          text_color = rgba(ffffffff)
          col.active = rgba(285577ff)
          col.inactive = rgba(2b2b2bff)
        }
      }


      # should be configured per-profile
      # monitor = eDP-1,3840X2160@60,0x100,1.6,vrr,1
      monitor = eDP-1,highres,auto,1.6,vrr,1
      # monitor = eDP-1,disable
      monitor = desc:LG Electronics 16MQ70 20NKZ005285,2560X1600@60,1598x0,1.6,vrr,1
      monitor = desc:LG Electronics LG Ultra HD 0x00043EAD,3840X2160@60,1920x0,1.5,vrr,1
      monitor = desc:LG Electronics LG HDR 4K 0x00020F5B,3840X2160@60,4480x0,1.5
      workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 1
      workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 4
      workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 5
      workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 2
      workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 7
      workspace = eDP-1, 3
      workspace = eDP-1, 6
      # workspace = DP-2, 1
      # workspace = DP-2, 4
      # workspace = DP-2, 5
      # workspace = DP-1, 2
      # workspace = DP-1, 7
      # workspace = eDP-1, 3
      # workspace = eDP-1, 6

      # telegram media viewer
      windowrule = float, title:^(KCalc)$

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
      ## @TODO: Make sure class matches for these two
      windowrule = idleinhibit fullscreen, class:^(chromium)$
      windowrule = idleinhibit fullscreen, class:^(brave)$

      # mouse movements
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
      bindm = $mod_ALT, mouse:272, resizewindow

      bind = $mod, Return, exec, $term
      bind = $mod, X, exec, ${swayLockCmd}
      # @TODO: Use the following instead: https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing
      bind = $mod, C, killactive
      # bind = $mod, R, forcerendererreload
      bind = $mod, R, exec, hyprctl reload
      bind = $mod, T, exec, ${toggle-group}
      bind = $mod_SHIFT, E, exec, nag-graphical 'Exit Hyprland?' 'pkill Hyprland'
      bind = $mod_SHIFT, P, exec, nag-graphical 'Power off?' 'systemctl poweroff -i, mode "default"'
      bind = $mod_SHIFT, R, exec, nag-graphical 'Reboot?' 'systemctl reboot'";
      bind = $mod_SHIFT, S, exec, nag-graphical 'Suspend?' 'systemctl suspend, mode "default"'
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
