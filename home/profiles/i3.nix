{ config, pkgs, launchAppsConfig, lockcmd, ... }:

let
  modifier = "Mod4";
  repeat_rate = "50";
  repeat_delay = "250";
  terminal = "${pkgs.trunk.kitty}/bin/kitty";
  light = "${pkgs.light}/bin/light";
  wofi = "${pkgs.wofi}/bin/wofi --insensitive";
  bemenu = "${pkgs.bemenu}/bin/bemenu-run -H 48 -p execute: -b --fn 'Terminus 24' --tf '#FFFFFF' --scf '#FFFFFF' --ff '#FFFFFF' --tb ''#FFFFFF --nf '#FFFFFF' --hf '#FFFFFF' --nb '#000000' --tb '#000000' --fb '#000000'";
  launcher = bemenu;
  pamixer = "${pkgs.pamixer}/bin/pamixer";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  i3fonts = {
    # names = [ i3font ];
    # names = [ "Terminus (TTF)" "FontAwesome" ];
    names = [ "Roboto" "FontAwesome" ];
    style = "Medium";
    size = 8.0;
  };
  keyboard_setup_cmd = pkgs.writeShellScript "keyboard_setup_cmd.sh" ''
    xset r rate ${repeat_delay} ${repeat_rate}
  '';
  idlecmd = pkgs.writeShellScript "i3idle.sh" ''
    killall xautolock
    ${pkgs.xautolock}/bin/xautolock \
    -detectsleep \
    -time 5 \
    -locker "${lockcmd}"
    # timeout 1000 "${pkgs.systemd}/bin/systemctl suspend"
  '';
  # idlecmd = pkgs.writeShellScript "i3idle.sh" ''
  #   echo ""
  # '';

  ## DON'T USE - CAUSES INFINITE LOOP IN journalctl -f
  ## FIGURE OUT BEFORE USING
  dropdownTerminalCmd = pkgs.writeShellScript "launchkitty.sh" ''
    open=$(ps aux | grep -i "kitty --class=dropdown" | grep -v grep)
    if [[ $open -eq 0 ]]
    then
      ${pkgs.trunk.kitty}/bin/kitty --class=dropdown --detach
      until i3-msg scratchpad show
      do
        echo "Waiting for Kitty to appear..."
      done
    else
      echo "Kitty is already open"
      i3-msg "[app_id=dropdown] scratchpad show"
    fi
  '';

  polybarLauncher = pkgs.writeShellScript "launch_polybar.sh" ''
    pkill polybar
    if type "xrandr"; then
      sleep 1
      PRIMARY=$(xrandr --query | grep " connected" | grep "primary" | cut -d" " -f1)
      OTHERS=$(xrandr --query | grep " connected" | grep -v "primary" | cut -d" " -f1)
      # Make sure tray is on primary monitor
      if [ "$PRIMARY" = "eDP-1" ]; then
        MONITOR=$PRIMARY polybar --reload laptop &
      else
        MONITOR=$PRIMARY polybar --reload bottom &
      fi
      sleep 0.5
      for m in $OTHERS; do
        if [ $m != $PRIMARY ]; then
          if [ "$m" = "eDP-1" ]; then
            MONITOR=$m polybar --reload laptop &
          else
            MONITOR=$m polybar --reload bottom &
          fi
        fi
      done
    else
      polybar --reload bottom &
    fi
  '';

  scregcp = pkgs.writeShellScript "scregcp.sh" ''
    function help_and_exit {
        if [ -n "''${1}" ]; then
            echo "''${1}"
        fi
        cat <<-EOF
        Usage: scregcp [-h|-s] [<screenshots_base_folder>]

        Take screenshot of a whole screen or a specified region,
        save it to a specified folder (current folder is default)
        and copy it to a clipboard.

           -h   - print help and exit
           -s   - take a screenshot of a screen region
    EOF
        if [ -n "''${1}" ]; then
            exit 1
        fi
        exit 0
    }

    if [ "''${1}" == '-h'  ]; then
        help_and_exit
    elif [ "''${1:0:1}" == '-' ]; then
        if [ "''${1}" != '-s' ]; then
            help_and_exit "error: unknown option ''${1}"
        fi
        base_folder="''${2}"
    else
        base_folder="''${1}"
        params="-window root"
    fi

    file_path=''${base_folder}$( date '+%Y-%m-%d_%H-%M-%S' )_screenshot.png
    ${pkgs.imagemagick}/bin/import ''${params} ''${file_path}
    ${pkgs.xclip}/bin/xclip -selection clipboard -target image/png -i < ''${file_path}
  '';
in
{
  imports = [
    # ../profiles/polybar-reedrw.nix
    ../profiles/polybar.nix
  ];

  home.packages = with pkgs; [
    gnome3.zenity
    libnotify
    # @TODO: de-dupe this with profiles/sway.nix
    (
      pkgs.writeTextFile {
        name = "nag-graphical";
        destination = "/bin/nag-graphical";
        executable = true;
        text = ''
          #!/usr/bin/env bash

          if zenity --question --text="$1"; then
            $2
          fi
        '';
      }
    )
  ];

  services.dunst = {
    enable = true;
    settings = {
      global = {
        geometry = "300x5-30+50";
        transparency = 10;
        frame_color = "#eceff1";
        font = "Terminus 14";
      };
      urgency_normal = {
        background = "#37474f";
        foreground = "#eceff1";
        timeout = 10;
      };
    };
  };

  xsession.windowManager.i3 = {
    enable = true;
    config = rec {
      inherit terminal;
      fonts = i3fonts;
      bars = [
        # {
        #   fonts = {
        #     names = [ "Terminus" ];
        #     size = 12.0;
        #   };
        #   statusCommand = "i3status-rs $HOME/.config/i3status-rust/config-top.toml";
        #   extraConfig = ''
        #     output nonprimary
        #   '';
        # }
        # {
        #   fonts = {
        #     names = [ "Terminus" ];
        #     size = 12.0;
        #     # # Unscaled
        #     # size = 16.0;
        #   };
        #   statusCommand = "i3status-rs $HOME/.config/i3status-rust/config-top.toml";
        #   extraConfig = ''
        #     output primary
        #   '';
        # }
      ];
      focus.followMouse = false;

      # Options: smart|urgent|focus|none
      focus.newWindow = "focus";
      window.border = 1;
      # @TODO: Fix:
      # window.commands = [
      #   { criteria = { app_id = "dropdown"; }; command = "floating enable"; }
      #   { criteria = { app_id = "dropdown"; }; command = "resize set 1000 640"; }
      #   { criteria = { app_id = "dropdown"; }; command = "move scratchpad"; }
      #   { criteria = { app_id = "dropdown"; }; command = "border pixel 1"; }
      # ];
      colors.focused = { background = "#4c7899"; border = "#4c7899"; childBorder = "#4c7899"; indicator = "#2e9ef4"; text = "#ffffff"; };

      startup = [
        ## Test path
        # { always = true; command = "exec xterm -e 'echo $PATH; sleep 500'"; }
        # Clear display as sometimes SDDM is still visible
        { always = true; command = "${pkgs.systemd}/bin/systemd-notify --ready || true"; notification = false; }
        # { always = true; command = "${pkgs.dunst}/bin/dunst"; notification = false; }
        { always = true; command = "tail -n0 -f $I3SOCK.xob | ${pkgs.xob}/bin/xob"; notification = false; }
        { always = true; command = "${pkgs.flashfocus}/bin/flashfocus"; notification = false; }
        { always = true; command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator --sm-disable"; notification = false; }
        { always = true; command = "${idlecmd}"; notification = false; }
        { always = true; command = "${keyboard_setup_cmd}"; notification = false; }
        { always = true; command = "xsetroot -solid black"; notification = false; }
        { always = true; command = "${polybarLauncher}"; notification = false; }
        { always = true; command = "blueman-applet"; notification = false; }
        # { command = "autorandr -c --match-edid"; notification = false; }
      ];
      keybindings = {
        "XF86MonBrightnessUp" = "exec ${light} -A 5 && ${light} -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86MonBrightnessDown" = "exec ${light} -U 5 && ${light} -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86AudioRaiseVolume" = "exec ${pamixer} -ui 2 && ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioLowerVolume" = "exec ${pamixer} -ud 2 && ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioMute" = "exec ${pamixer} --toggle-mute && ( ${pamixer} --get-mute && echo 0 > $SWAYSOCK.wob ) || ${pamixer} --get-volume > $SWAYSOCK.wob";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "XF86AudioPrev" = "exec ${playerctl} pevious";
        "XF86AudioNext" = "exec ${playerctl} next";

        "ctrl+Shift+3" = "exec \"mkdir -p ~/Pictures/screenshots; ${scregcp} ~/Pictures/screenshots/\"";
        "ctrl+Shift+4" = "exec \"mkdir -p ~/Pictures/screenshots; ${scregcp} -s ~/Pictures/screenshots/\"";

        "${modifier}+Return" = "exec ${terminal}";
        ## CURRENTLY CAUSES INFINTE LOOP
        # "${modifier}+Shift+Return" = "exec ${dropdownTerminalCmd}";
        "${modifier}+x" = "exec ${lockcmd}";
        "${modifier}+c" = "kill";
        "${modifier}+r" = "exec ${pkgs.i3}/bin/i3-msg restart";
        "${modifier}+y" = "exec \"autorandr -c --match-edid";
        "${modifier}+t" = "layout toggle tabbed split";
        "${modifier}+Shift+e" = "exec nag-graphical 'Exit i3?' 'i3-msg exit'";
        "${modifier}+Shift+p" = "exec nag-graphical 'Power off?' 'i3-msg exec systemctl poweroff -i'";
        "${modifier}+Shift+r" = "exec nag-graphical 'Reboot?' 'i3-msg exec systemctl reboot'";
        "${modifier}+Shift+s" = "exec nag-graphical 'Suspend?' 'i3-msg exec systemctl suspend'";
        "${modifier}+Control+Shift+l" = "move workspace to output right";
        "${modifier}+Control+Shift+h" = "move workspace to output left";
        "${modifier}+Control+Shift+j" = "move workspace to output down";
        "${modifier}+Control+Shift+k" = "move workspace to output up";

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
      # No title bars
      default_border pixel 1
      default_floating_border pixel 1

      # home-manager config doesn't support "workspace" for this option
      # Options: yes|no|force|workspace
      # Switches workspace if a window there gains focus
      focus_wrapping workspace

      # Don't idle on fullscreen
      for_window [class="^.*"] inhibit_idle fullscreen

      # Floating windows
      for_window [class="gnome-calculator"] floating enable
      for_window [class="Thunar"] floating enable
      for_window [class="Thunar"] resize set 1600 1200
      for_window [class="Org.gnome.Nautilus"] floating enable
      for_window [class="Org.gnome.Nautilus"] resize set 1600 1200
      for_window [class="Nemo"] floating enable
      for_window [class="Nemo"] resize set 1600 1200
      for_window [class="Zenity"] floating enable
      for_window [class="QjackCtl"] floating enable
      for_window [class="Teensy-loader-gui-bin"] floating enable
      for_window [class="zoom"] floating enable
      for_window [class=".blueman-manager-wrapped"] floating enable
      for_window [class=".blueman-manager-wrapped"] resize set 768 1280
      for_window [class="feh"] fullscreen enable

      ${launchAppsConfig}
    '';
  };
}
