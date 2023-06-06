args@{ inputs, config, lib, pkgs, launchAppsConfig, hostParams, ... }:

let
  emoji = "${pkgs.wofi-emoji}/bin/wofi-emoji";
  rofi = "${pkgs.rofi-wayland}/bin/rofi -show drun -theme ~/.config/rofi/launcher.rasi";
  wofi = "${pkgs.wofi}/bin/wofi --show run -W 400 -H 300";
  launcher = rofi;
  swayLockCmd = pkgs.writeShellScript "swaylock.sh" ''
    ${pkgs.swaylock-effects}/bin/swaylock -c '#000000' --indicator-radius 100 --indicator-thickness 20 --show-failed-attempts
  '';
in
{
  imports = [
    ./swaynotificationcenter.nix
    ./network-manager-applet.nix
    ./rofi.nix
    ( import ./sway-idle.nix (args // { swayLockCmd = swayLockCmd; }))
    ./waybar.nix
    ./wlsunset.nix
  ];

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # NVidia support
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";

    ## Causes Hyprland to crash
    # GBM_BACKEND = "nvidia-drm";
    GBM_BACKEND = "nvidia";
  };

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

  wayland.windowManager.hyprland = {
    enable = true;

    extraConfig = ''
      $mod = SUPER

      $term = ${pkgs.trunk.kitty}/bin/kitty

      ## Refresh services
      exec = systemctl --user restart mako
      exec = systemctl --user restart network-manager-applet
      exec = systemctl --user restart wlsunset

      exec-once = ${pkgs.hyprpaper}/bin/hyprpaper

      ## scale Xorg apps
      exec-once = xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 1.5

      ## @TODO
      ## 1. Is this already being set?
      ## 2. Is it being set BEFORE portals are executed?
      ## SEE: https://wiki.hyprland.org/FAQ/#some-of-my-apps-take-a-really-long-time-to-open
      # exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      # exec-once = systemctl --user start clight
      # exec-once = eww open bar
      exec = pkill waybar; ${pkgs.waybar}/bin/waybar

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
        gaps_in = 5
        gaps_out = 5
        border_size = 1
      }

      decoration {
        rounding = 8
        blur = 1
        blur_size = 3
        blur_passes = 3
        blur_new_optimizations = 1

        drop_shadow = 1
        shadow_ignore_window = 1
        shadow_offset = 2 2
        shadow_range = 4
        shadow_render_power = 1
        col.shadow = 0x55000000
      }

      animations {
        enabled = 1
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

      # should be configured per-profile
      # monitor = DP-1, preferred, auto, 1
      # monitor = DP-2, preferred, auto, 1
      # monitor = eDP-1, preferred, auto, 2
      monitor = eDP-1,preferred,0x910,2.0
      monitor = desc:LG Electronics LG Ultra HD 0x00043EAD,preferred,1920x0,1.5
      monitor = desc:LG Electronics LG HDR 4K 0x00020F5B,preferred,4480x0,1.5
      workspace = DP-2, 1
      workspace = DP-2, 4
      workspace = DP-2, 5
      workspace = DP-1, 2
      workspace = DP-1, 7
      workspace = eDP-1, 3
      workspace = eDP-1, 6

      # telegram media viewer
      windowrule = float, title:^(Media viewer)$

      # make Firefox PiP window floating and sticky
      windowrule = float, title:^(Picture-in-Picture)$
      windowrule = pin, title:^(Picture-in-Picture)$

      # throw sharing indicators away
      windowrule = workspace special silent, title:^(Firefox — Sharing Indicator)$
      windowrule = workspace special silent, title:^(.*is sharing (your screen|a window)\.)$

      # workspace 1
      windowrule = workspace 1, silent, class:^(chromium)$
      windowrule = workspace 1 silent, class:^(firefox)$

      # workspace 2
      windowrule = workspace 2, silent, class:^(kitty)$

      # workspace 3
      windowrule = workspace 3 silent, class:^(slack)$
      windowrule = workspace 3, title:^(Signal)$

      # workspace 4
      windowrule = tile, class:^(Spotify)$
      windowrule = workspace 4 silent, class:^(Spotify)$
      windowrule = tile, class:^(Brave)$
      windowrule = workspace 4 silent, class:^(Brave)$

      # workspace 7
      windowrule = workspace 7, title:^(.*Discord.*)$

      # idle inhibit while watching videos
      windowrule = idleinhibit focus, class:^(mpv)$
      windowrule = idleinhibit fullscreen, class:^(firefox)$
      ## @TODO: Make sure class matches for these two
      windowrule = idleinhibit fullscreen, class:^(chromium)$
      windowrule = idleinhibit fullscreen, class:^(brave)$

      # mouse movements
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
      bindm = $mod ALT, mouse:272, resizewindow

      bind = $mod, Return, exec, $term
      bind = $mod, X, exec, ${swayLockCmd}
      bind = $mod, C, killactive
      bind = $mod, R, forcerendererreload
      bind = $mod, T, togglegroup
      bind = $mod SHIFT, E, exec, nag-graphical 'Exit Hyprland?' 'pkill Hyprland'
      bind = $mod SHIFT, P, exec, nag-graphical 'Power off?' 'swaymsg exec systemctl poweroff -i, mode \"default\"'
      bind = $mod SHIFT, R, exec, nag-graphical 'Reboot?' 'swaymsg exec systemctl reboot'";
      bind = $mod SHIFT, S, exec, nag-graphical 'Suspend?' 'swaymsg exec systemctl suspend, mode \"default\"'
      bind = $mod, F, fullscreen,
      bind = $mod SHIFT CTRL, L, movecurrentworkspacetomonitor, r
      bind = $mod SHIFT CTRL, H, movecurrentworkspacetomonitor, l
      bind = $mod SHIFT CTRL, K, movecurrentworkspacetomonitor, u
      bind = $mod SHIFT CTRL, J, movecurrentworkspacetomonitor, d

      bind = $mod CTRL, L, resizeactive, 10 0
      bind = $mod CTRL, H, resizeactive, -10 0
      bind = $mod CTRL, K, resizeactive, 0 -10
      bind = $mod CTRL, J, resizeactive, 0 10

      # move focus
      bind = $mod, H, movefocus, l
      bind = $mod, L, movefocus, r
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d

      bind = $mod SHIFT, L, movewindow, r
      bind = $mod SHIFT, H, movewindow, l
      bind = $mod SHIFT, K, movewindow, u
      bind = $mod SHIFT, J, movewindow, d

      # compositor commands
      bind = $mod, G, togglegroup,
      bind = $mod SHIFT, N, changegroupactive, f
      bind = $mod SHIFT, P, changegroupactive, b
      bind = $mod, SPACE, togglefloating,
      # bind = $mod, P, pseudo,
      bind = $mod ALT, , resizeactive,



      # utility
      # launcher
      bind = $mod, P, exec, ${launcher}
      # terminal
      # logout menu
      bind = $mod, Escape, exec, wlogout -p layer-shell
      # lock screen
      bind = $mod, X, exec, loginctl lock-session
      # emoji picker
      bind = $mod, E, exec, ${emoji}
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
      bind = $mod SHIFT CTRL, R, exec, grimblast --notify --cursor copysave output

      bind = ALT, Print, exec, grimblast --notify --cursor copysave screen
      bind = $mod SHIFT ALT, R, exec, grimblast --notify --cursor copysave screen

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
            bind = $mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
          ''
        )
        10)}

      # special workspace
      bind = $mod SHIFT, grave, movetoworkspace, special
      bind = $mod, grave, togglespecialworkspace, eDP-1

      # cycle workspaces
      bind = $mod, bracketleft, workspace, m-1
      bind = $mod, bracketright, workspace, m+1

      # cycle monitors
      bind = $mod SHIFT, braceleft, focusmonitor, l
      bind = $mod SHIFT, braceright, focusmonitor, r
    '';
  };
}
