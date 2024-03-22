{ lib, pkgs, launchAppsConfig, hostParams, userParams, ... }:

let
  swaynagmode = pkgs.callPackage ../../pkgs/swaynagmode {};
in
let
  keyboardConfig = {
    repeat_rate = "50";
    repeat_delay = "250";
  };
  swayfont = "Iosevka Bold 18";
  light = "${pkgs.light}/bin/light";
  # bemenu = "BEMENU_BACKEND=wayland ${pkgs.bemenu}/bin/bemenu-run -H 32 --no-overlap -p execute: -b --fn 'Terminus 18' --tf '#FFFFFF' --scf '#FFFFFF' --ff '#FFFFFF' --tb ''#FFFFFF --nf '#FFFFFF' --hf '#FFFFFF' --nb '#000000' --tb '#000000' --fb '#000000'";
  # bespokeMenu = "${pkgs.termite}/bin/termite --name=launcher -e \"${pkgs.bashInteractive}/bin/bash -c 'compgen -c | ${pkgs.gnugrep}/bin/grep -v fzf | ${pkgs.coreutils}/bin/sort -u | ${pkgs.fzf}/bin/fzf --layout=reverse | ${pkgs.findutils}/bin/xargs -r ${pkgs.sway}/bin/swaymsg -t command exec'\"";
  # wofi = "${pkgs.wofi}/bin/wofi --show run -W 400 -H 300";
  rofi = "${pkgs.rofi-wayland}/bin/rofi -show drun -theme ~/.config/rofi/launcher.rasi";
  launcher = rofi;
  pamixer = "${pkgs.pamixer}/bin/pamixer";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  swayfonts = {
    names = [ swayfont ];
    # names = [ "Terminus (TTF)" "FontAwesome" ];
    style = "Medium";
    size = 10.0;
  };
  swayLockCmd = pkgs.callPackage ../../pkgs/sway-lock-command { };
  dropdownTerminalCmd = pkgs.writeShellScript "launchtty.sh" ''
    open=$(ps aux | grep -i "${userParams.tty} --class=dropdown" | grep -v grep)
    if [[ $open -eq 0 ]]
    then
      ${userParams.tty} --class=dropdown --detach
      until swaymsg scratchpad show
      do
        echo "Waiting for ${userParams.tty} to appear..."
      done
    else
      echo "${userParams.tty} is already open"
      swaymsg "[app_id=dropdown] scratchpad show"
    fi
  '';

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =''
      gnome-schema=org.gnome.desktop.interface
      ${pkgs.glib}/bin/gsettings set $gnome-schema gtk-theme 'Adwaita'
      ${pkgs.glib}/bin/gsettings set $gnome-schema icon-theme 'Adwaita'
      ${pkgs.glib}/bin/gsettings set $gnome-schema cursor-theme 'Adwaita'
      ${pkgs.glib}/bin/gsettings set $gnome-schema font-name 'Sans 18'
      ${pkgs.glib}/bin/gsettings set $gnome-schema font-name 'Sans 18'
      # Don't use middle button paste for trackpoint
      ${pkgs.glib}/bin/gsettings set $gnome-schema gtk-enable-primary-paste false
    '';
  };
in
{
  imports = [
    # ./mako.nix
    ./swaynotificationcenter.nix
    ./network-manager-applet.nix
    ./rofi.nix
    ./sway-idle.nix
    ./waybar.nix
    ./wlsunset.nix
    ## Wayland Brightness/Volume overlay bar
    ## Doesn't work, system service keeps restarting
    # ./wob.nix
  ];

  # For configure-gtk above. Haven't really run into issues, perhaps this should be removed and wrap any apps that need it.
  xdg.dataFile."glib-2.0".source = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0";

  ## @TODO: Should this even be here? Or included by apps that need it? Haven't really run into any issues without it
  ## For gtk widgets. Note that there is no glib-2.0 at the end
  # xdg.dataFile.${pkgs.gtk3.name}.source = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";

  # Block auto-sway reload, Sway crashes if allowed to reload this way.
  xdg.configFile."sway/config".onChange = lib.mkForce "";

  xdg.configFile."swaynag/config".text = ''
    font=Terminus 18
  '';

  home.packages = with pkgs; [
    configure-gtk
    gnome3.zenity
    swaynagmode
    networkmanagerapplet
    imv
    i3status
    wl-clipboard
    gnome3.zenity
    weston
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

  wayland.windowManager.sway = {
    enable = true;
    # nVidia support
    extraOptions = [
      "--unsupported-gpu"
    ];
    wrapperFeatures = {
      base = false;
      gtk = false;
    };
    xwayland = true;
    config = rec {
      fonts = swayfonts;
      bars = [
        {
          # command = "pkill waybar || true; ${pkgs.waybar}/bin/waybar";
          command = "${pkgs.waybar}/bin/waybar";
        }
      ];
      # focus.followMouse = "always";
      focus.followMouse = "no";

      # Options: smart|urgent|focus|none
      focus.newWindow = "focus";
      window.border = 1;
      window.commands = [
        { criteria = { app_id = "dropdown"; }; command = "floating enable"; }
        { criteria = { app_id = "dropdown"; }; command = "resize set 1000 640"; }
        { criteria = { app_id = "dropdown"; }; command = "move scratchpad"; }
        { criteria = { app_id = "dropdown"; }; command = "border pixel 1"; }
      ];

      # https://www.mankier.com/5/sway-input
      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "disabled";
          accel_profile = "adaptive";

          # none|button_areas|clickfinger
          # Choose "button_areas" for left and right buttons
          # Choode "clickfinger" for one-button touchpad
          ## @TODO: Move this to hostParams
          click_method = if builtins.hasAttr "touchpad_click_method" hostParams
                         then hostParams.touchpad_click_method
                         else "clickfinger";
          drag = "enabled";
          # dwt = "disable-while-typing"
          dwt = "enabled";
          # events = "disabled_on_external_mouse";
          middle_emulation = "enabled";
          pointer_accel = "0.3";
          scroll_method = "two_finger";
        };
        # Mouse
        "type:pointer" = {
          accel_profile = "adaptive";
          pointer_accel = "0.7";
        };
        # Have to specify a *single* keyboard directly, rather than with "*", "type:keyboard", or with multiple keyboard
        # definitions, otherwise Firefox crashes on Sway reload.
        # See: https://major.io/2022/05/24/sway-reload-causes-a-firefox-crash/
        # To get keyboard identifier: swaymsg -t get_inputs | jq -r '.[].identifier' | grep -i keyboard

        # "10730:258:Kinesis_Freestyle_Edge_Keyboard" = keyboardConfig;
        # "1:1:AT_Translated_Set_2_keyboard" = keyboardConfig;
        "type:keyboard" = keyboardConfig;
        "2:10:TPPS/2_Elan_TrackPoint" = {
          accel_profile = "flat";
          pointer_accel = "0.0";
        };
      };
      output."*" = if builtins.hasAttr "wallpaper" hostParams then {
        background = "${hostParams.wallpaper} fill";
      } else { };
      startup = [
        # { always = true; command = "${dbus-sway-environment}/bin/dbus-sway-environment"; }
        { always = true; command = "${configure-gtk}/bin/configure-gtk"; }

        # Bring in environment into systemd
        { always = true; command = "systemctl --user import-environment"; }

        # Notification daemon
        { always = true; command = "systemctl --user restart mako"; }

        # Network manager applet
        { always = true; command = "systemctl --user restart network-manager-applet"; }

        # Wayland volume/brightness overlay bar
        # { always = true; command = "systemctl --user restart wob"; }

        # Screen lock
        { always = true; command = "systemctl --user restart sway-idle"; }

        # Let init system know that system is ready
        { always = true; command = "${pkgs.systemd}/bin/systemd-notify --ready || true"; }

        # bluetooth applet
        { always = true; command = "${pkgs.blueman}/bin/blueman-applet"; }

        ## Load Chinese input method
        ## Neither of these work
        { always = true; command = "${pkgs.fcitx5-with-addons}/bin/fcitx5 -d --replace"; }
        # { always = true; command = "ibus-daemon -rxRd"; }

        # Night time dimming/coloration
        { always = true; command = "systemctl --user restart wlsunset"; }

        ## Too annoying with a background
        # Flash screen when focus changes
        # { always = true; command = "${pkgs.flashfocus}/bin/flashfocus"; }

        # Kanshi doesn't detect when sway is reloaded, so it won't apply the monitor
        # config to the freshly loaded sway.  Restart it so it applies the config on sway restart.
        # @TODO: This appears to restart right when apps are being opened on various workspaces,
        #       potentially causing the the wrong app to launch on the wrong workspace
        # - A delay is added and kanshi is run a second time to make sure it's not missed at startup
        { always = true; command = "systemctl --user restart kanshi; sleep 5; systemctl --user restart kanshi"; }
      ];
      modifier = "Mod4";
      keybindings = {
        "XF86MonBrightnessUp" = "exec ${light} -A 5 && ${light} -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86MonBrightnessDown" = "exec ${light} -U 5 && ${light} -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86AudioRaiseVolume" = "exec ${pamixer} -ui 2 && ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioLowerVolume" = "exec ${pamixer} -ud 2 && ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioMute" = "exec ${pamixer} --toggle-mute && ( ${pamixer} --get-mute && echo 0 > $SWAYSOCK.wob ) || ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "XF86AudioPrev" = "exec ${playerctl} pevious";
        "XF86AudioNext" = "exec ${playerctl} next";

        # Capture full screen
        "ctrl+shift+3" = "exec ${pkgs.grim}/bin/grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png";
        # Capture selection
        "ctrl+shift+4" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp -d)\" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png";

        "${modifier}+Return" = "exec ${userParams.tty}";
        "${modifier}+Shift+Return" = "exec ${dropdownTerminalCmd}";
        "${modifier}+x" = "exec ${swayLockCmd}";
        "${modifier}+c" = "kill";
        ## Force kill
        "${modifier}+Shift+c" = "exec swaymsg -t get_tree | jq '.. | select(.type?) | select(.focused==true).pid' | xargs -L 1 kill -9";
        "${modifier}+r" = "reload";
        "${modifier}+t" = "layout toggle tabbed split";
        "${modifier}+y" = "exec systemctl --user restart kanshi";
        # "${modifier}+Shift+e" = "exec swaynagmode -t 'warning' -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";
        # "${modifier}+Shift+p" = "exec swaynagmode -t 'warning' -m 'Power off?' -b 'Yes' 'swaymsg exec systemctl poweroff -i, mode\"default\"'";
        # "${modifier}+Shift+r" = "exec swaynagmode -t 'warning' -m 'Reboot?' -b 'Yes' 'swaymsg exec systemctl reboot'";
        # "${modifier}+Shift+s" = "exec swaynagmode -t 'warning' -m 'Suspend?' -b 'Yes' 'swaymsg exec systemctl suspend, mode \"default\"'";
        "${modifier}+Shift+e" = "exec nag-graphical 'Exit sway?' 'swaymsg exit'";
        "${modifier}+Shift+p" = "exec nag-graphical 'Power off?' 'swaymsg exec systemctl poweroff -i, mode \"default\"'";
        "${modifier}+Shift+r" = "exec nag-graphical 'Reboot?' 'swaymsg exec systemctl reboot'";
        "${modifier}+Shift+s" = "exec nag-graphical 'Suspend?' 'swaymsg exec systemctl suspend, mode \"default\"'";
        "${modifier}+Shift+f" = "fullscreen global";
        "${modifier}+Control+Shift+l" = "move workspace to output right";
        "${modifier}+Control+Shift+h" = "move workspace to output left";
        "${modifier}+Control+Shift+j" = "move workspace to output down";
        "${modifier}+Control+Shift+k" = "move workspace to output up";
        "${modifier}+Control+l" = "resize shrink width 1px or 1 ppt";
        "${modifier}+Control+h" = "resize grow width 1 px or 1 ppt";
        "${modifier}+Control+j" = "resize shrink height 1 px or 1 ppt";
        "${modifier}+Control+k" = "resize grow height 1 px or 1 ppt";

        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+space" = "floating toggle";
        "${modifier}+w" = "sticky toggle";
        "${modifier}+a" = "focus parent";
        "${modifier}+d" = "exec ${launcher}";
        "${modifier}+p" = "exec ${launcher}";

        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";
      };
    };
    extraConfig = ''
      ## disable middle click paste
      ## Not available until 1.9
      # primary_selection disabled

      hide_edge_borders smart

      # home-manager config doesn't support "workspace" for this option
      # Options: yes|no|force|workspace
      # Switches workspace if a window there gains focus
      focus_wrapping workspace

      for_window [app_id="^launcher$"] floating enable, border none, opacity 0.8

      # Don't idle on fullscreen
      for_window [class="^.*"] inhibit_idle fullscreen
      for_window [app_id="^.*"] inhibit_idle fullscreen

      # Floating windows
      for_window [app_id="org.gnome.Calculator"] floating enable
      for_window [app_id="thunar"] floating enable
      for_window [app_id="thunar"] resize set 1024 768
      for_window [app_id="vlc"] floating enable
      for_window [app_id="org.gnome.Nautilus"] floating enable; resize set 1400 1000
      for_window [app_id="nemo"] floating enable
      for_window [app_id="nemo"] resize set 1600 1200
      for_window [app_id="gthumb"] floating enable; fullscreen enable
      for_window [app_id="org.kde.kcalc"] floating enable
      for_window [class="AVPNC"] floating enable
      for_window [app_id="zenity"] floating enable
      for_window [title=".*QjackCtl.*"] floating enable
      for_window [title="Teensy"] floating enable
      for_window [title="^Zoom.*"] floating enable
      for_window [app_id="^org.kde.polkit-kde-authentication-agent.*"] floating enable
      for_window [title="^Minecraft 1.*"] floating enable; fullscreen enable
      for_window [class="com.bitwig.BitwigStudio" title="Manage Licenses"] floating enable
      for_window [class="com.bitwig.BitwigStudio" title="Bitwig Studio \d.*"] floating enable
      for_window [title="Firefox — Sharing Indicator"] floating enable
      for_window [app_id="firefox" title="Extension.*Bitwarden.*"] floating enable
      for_window [app_id="brave-.*" title="Bitwarden"] floating enable
      for_window [app_id="chrome-.*" title="Bitwarden"] floating enable
      # for_window [app_id="Waydroid"] floating enable

      # Zoom Meeting App
      #
      # Default for all windows is non-floating.
      #

      # For pop up notification windows that don't use notifications api
      for_window [app_id="zoom" title="^zoom$"] border none, floating enable

      # For specific Zoom windows
      for_window [app_id="zoom" title="^(Zoom|About)$"] border pixel, floating enable

      ## Settings window has no app_id for some reason
      # for_window [app_id="" title="Settings"] floating enable, floating_minimum_size 960 x 700

      # Open Zoom Meeting windows on a new workspace (a bit hacky)
      for_window [app_id="zoom" title="Zoom Meeting(.*)?"] workspace next_on_output --create, move container to workspace current, floating disable, inhibit_idle open

      ## Alternate set (if above set doesn't work)
      # for_window [app_id="zoom"] floating enable
      # for_window [app_id="zoom" title="Choose ONE of the audio conference options"] floating enable
      # for_window [app_id="zoom" title="zoom"] floating enable
      # for_window [app_id="zoom" title="Zoom Meeting"] floating disable
      # for_window [app_id="zoom" title="Zoom - Free Account"] floating disable

      # Cursor
      seat seat0 xcursor_theme Adwaita 24

      # nag
      set {
        $nag         exec swaynagmode
        $nag_exit    $nag --exit
        $nag_confirm $nag --confirm
        $nag_select  $nag --select
      }
      mode "nag" {
        bindsym {
          Ctrl+d    mode "default"

          Ctrl+c    $nag_exit
          q         $nag_exit
          Escape    $nag_exit

          # This doesn't work because swaynagmode as launched by sway
          # doesn't have a TTY. Is that because sway is launched by a
          # display manager rather than from the command line?
          Return    $nag_confirm

          Tab       $nag_select prev
          Shift+Tab $nag_select next

          Left      $nag_select next
          Right     $nag_select prev

          Up        $nag_select next
          Down      $nag_select prev
        }
      }

      ### SwayFX

      # corner_radius 10
      # smart_corner_radius enable
      # layer_effects "waybar" blur enable; shadows enable;
      # layer_effects notifications blur enable; shadows enable;
      # blur enable
      # shadows enable
      # shadow_blur_radius 20
      # shadow_color #0000007F
      # default_dim_inactive 0.20

      ${launchAppsConfig}
    '';
  };
}
