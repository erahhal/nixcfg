{  config, inputs, pkgs, hostParams, ... }:
let
  hyprlockCommand = pkgs.callPackage ../../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
  exit-hyprland = pkgs.writeShellScript "exit-hyprland" ''
    ${builtins.readFile ../../scripts/kill-all-apps.sh}

    pkill Hyprland
  '';
  toggle-drawer = "pkill -10 nwg-drawer";

  # launch = ''${pkgs.nwg-menu}/bin/nwg-menu -wm hyprland -d -term foot -cmd-lock "${hyprlockCommand}" -cmd-logout "${exit-hyprland}" -cmd-restart "systemctl reboot" -cmd-shutdown "systemctl -i poweroff"'';
  launch = ''${pkgs.nwg-drawer}/bin/nwg-drawer -open'';
  logout = "${pkgs.nwg-bar}/bin/nwg-bar";
  check-online-script = pkgs.writeShellScriptBin "check-online-script" ''
    ## Mullvad statuses
    ## - Disconnected
    ## - Connecting
    ## - Connected
    mullvad_status=$(${pkgs.mullvad}/bin/mullvad status)
    if echo $mullvad_status | ${pkgs.gnugrep}/bin/grep -q Connecting; then
      echo '{ "text": "mullvadconnecting", "alt": "mullvadconnecting", "tooltip": "Mullvad Connecting...", "class": "mullvadconnecting" }'
      exit
    elif echo $mullvad_status | ${pkgs.gnugrep}/bin/grep -q Connected; then
      echo '{ "text": "mullvadconnected", "alt": "mullvadconnected", "tooltip": "Mullvad Connected", "class": "mullvadconnected" }'
      exit
    fi

    if ${pkgs.procps}/bin/pgrep -x "openconnect" > /dev/null; then
      URL=https://data.netflix.net
    else
      URL=https://github.com
    fi
    ${pkgs.wget}/bin/wget -q --timeout=1 --tries=1 --spider $URL
    # "tooltip" field can't match the icon name, or else it will be replaced by icon
    #  so it is capitalized here to avoid that.
    if [ $? -eq 0 ]; then
      echo "{ \"text\": \"online\", \"alt\": \"online\", \"tooltip\": \"Online ($URL)\", \"class\": \"online\" }"
    else
      echo "{ \"text\": \"online\", \"alt\": \"offline\", \"tooltip\": \"Offline ($URL)\", \"class\": \"offline\" }"
    fi
  '';
in
{
  home.packages = with pkgs; [
    waybar
  ];

  systemd.user.services.nwg-drawer = {
    Unit = {
      Description = "Start the nwg-drawer resident service";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.nwg-drawer}/bin/nwg-drawer -r -wm hyprland -fm ${pkgs.nemo}/bin/nemo -g '${config.gtk.theme.name}' -i '${config.gtk.iconTheme.name}' -nofs -pbuseicontheme -pbexit '${exit-hyprland}' -pblock '${hyprlockCommand}' -pbpoweroff 'systemctl poweroff' --pbreboot 'systemctl reboot' --pbsleep '${hyprlockCommand} suspend'";
      PassEnvironment = [
        "HOME"
        "XDG_DATA_HOME"
        "XDG_CONFIG_HOME"
        "XDG_CACHE_HOME"
        "XDG_RUNTIME_DIR"
        "WAYLAND_DISPLAY"
        "QT_QPA_PLATFORMTHEME"
        "QT_SCALE_FACTOR"
        "XCURSOR_SIZE"
        "XCURSOR_THEME"
        "HYPRCURSOR_SIZE"
        "HYPRCURSOR_THEME"
        "GDK_SCALE"
        "XAUTHORITY"
        "XDG_CURRENT_DESKTOP"
      ];
      Environment = [
        "HOME=%h"  # %h is a special variable that expands to the user's home directory
      ];
    };
  };

  programs.waybar = {
    enable = true;
    package = pkgs.unstable.waybar;
    # package = inputs.waybar.packages.${pkgs.system}.waybar;
    # If enabled, this will load waybar separately from sway's own config, leading to two bars being loaded
    systemd.enable = false;
    settings = {
      mainBar = {
        ## Make sure menus are on top of the bar
        layer = "bottom";

        position = "bottom";

        modules-left = if (hostParams.waybarSimple or false) then [
          "custom/launcher"
          "sway/workspaces"
          "sway/mode"
          "sway/window"
          "wlr/taskbar"
          "hyprland/workspaces"
          "hyprland/window"
        ] else [
          "custom/launcher"
          "sway/workspaces"
          "sway/mode"
          "sway/window"
          "hyprland/workspaces"
          "hyprland/window"
        ];

        "sway/workspaces" = {
          all-outputs = true;
        };

        "hyprland/workspaces" = {
          all-outputs = true;
        };

        "wlr/taskbar" = {
          format= "{icon}";
          icon-size = 14;
          icon-theme = "Numix-Circle";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [ "Alacritty" ];
          app_ids-mapping = {
            firefoxdeveloperedition = "firefox-developer-edition";
          };
          rewrite = {
            "Firefox Web Browser" = "Firefox";
            "Foot Server" = "Terminal";
          };
        };

        modules-right = if (hostParams.waybarSimple or false) then [
          "pulseaudio"
          "cpu"
          "clock"
          "idle_inhibitor"
          "custom/toggletheme"
          "custom/online-monitor"
          "tray"
          "custom/notification"
        ] else [
          "network"
          "backlight"
          "pulseaudio"
          "battery"
          "cpu"
          "memory"
          # "temperature"
          "clock"
          "idle_inhibitor"
          "custom/toggletheme"
          "custom/online-monitor"
          "tray"
          # "custom/power"
          "custom/notification"
        ];

        "custom/left-arrow-dark" = {
          format = "";
          tooltip = false;
        };

        "custom/left-arrow-cap" = {
          format = "";
          tooltip = false;
        };

        "custom/left-arrow-light" = {
          format = "";
          tooltip = false;
        };

        "custom/right-arrow-dark" = {
          format = "";
          tooltip = false;
        };

        "custom/right-arrow-cap" = {
          format = "";
          tooltip = false;
        };

        "custom/right-arrow-light" = {
          format = "";
          tooltip = false;
        };

        "sway/mode" = { format = ''<span style="italic">{}</span>''; };

        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "";
          on-click = "helvum";
          format-icons = ["" "" ""];
        };

        pulseaudio = {
          tooltip = false;
          scroll-step = 5;

          format = "{icon} {volume}% {format_source}";
          format-muted = "🔇 {format_source}";
          format-bluetooth = "{icon} {volume}% {format_source}";
          format-bluetooth-muted = "🔇 {icon} {format_source}";

          on-click = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
          on-click-middle = "${pkgs.qpwgraph}/bin/qpwgraph";

          format-icons = {
            car = "";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
            handsfree = "";
            headphones = "";
            headset = "";
            phone = "";
            portable = "";
          };
          format-source = " {volume}%";
          format-source-muted = "";
        };

        "river/tags" = {
          num-tags = 6;
        };

        network = {
          tooltip = false;
          interval = 1;
          format-alt = "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
          format-disconnected = "Disconnected ⚠";
          format-ethernet = "{ifname}: {ipaddr}/{cidr}";
          format-linked = "{ifname} (No IP) ";
          format-wifi = "{essid} ({signalStrength}%) ";
        };

        backlight = {
          tooltip = false;
          format = " {}%";
          interval = 1;
          on-scroll-up = "light -A 5";
          on-scroll-down = "light -U 5";
        };

        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C";
          format-icons = [ "" "" "" ];
        };

        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 20;
          };
          format = "{icon}   {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            # activated = "⛾";
            # activated = "☕";
            deactivated = "";
          };
        };

        "custom/toggletheme" = {
          tooltip = false;
          on-click = "systemctl --user restart toggle-theme";
        };

        "custom/online-monitor" = {
          tooltip = true;
          format = "{icon}";
          format-icons = {
            online = "📲";
            offline = "📵";
            mullvadconnecting = "󱎛";
            mullvadconnected = "󱅛";
          };
          exec = "${check-online-script}/bin/check-online-script";
          interval = 2;
          return-type = "json";
        };

        tray = {
          icon-size = 18;
          spacing = 10;
        };

        clock = {
          format = "{:%I:%M %p   %m/%d/%Y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            on-click-right = "mode";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        cpu = {
          interval = 5;
          format = "  {usage}%";
          max-length = 3;
        };

        memory = {
          interval = 30;
          format = " {}%";
          max-length = 10;
        };

        "custom/media" = {
          interval = 30;
          format = "{icon} {}";
          return-type = "json";
          max-length = 20;
          format-icons = {
            spotify = " ";
            default = " ";
          };
          escape = true;
          exec = "$HOME/.config/system_scripts/mediaplayer.py 2> /dev/null";
          on-click = "playerctl play-pause";
        };

        "custom/launcher" ={
          tooltip = false;
          format = if (hostParams.waybarSimple or false) then "🔘" else "ꅾ";
          on-click = toggle-drawer;
          on-click-right = "pkill wofi";
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon} {}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which ${pkgs.swaynotificationcenter}/binswaync-client";
          exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
          # interval = 2;
          on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
          on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
          escape = true;
        };

        "custom/power" = {
          format = "⏻";
          on-click = logout;
          on-click-right = "pkill wofi";
        };
      };
    };
  };
}

