{  pkgs, ... }:
let
  # launch = pkgs.writeShellScript "launch.sh" ''
  #   if ${pkgs.procps}/bin/pgrep -x ".wofi-wrapped" >/dev/null; then
  #     pkill wofi
  #     exit
  #   fi
  #   GDK_DPI_SCALE=1.5 ${pkgs.wofi}/bin/wofi --show run --location bottom_left -x 6 -y -34 -W 400 -H 500
  # '';
  # # @TODO: de-duplicate swaylock command here
  # logout = pkgs.writeShellScript "logout.sh" ''
  #   if ${pkgs.procps}/bin/pgrep -x ".wofi-wrapped" >/dev/null; then
  #     pkill wofi
  #     exit
  #   fi
  #   choice=$(${pkgs.coreutils}/bin/printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | GDK_DPI_SCALE=1.5 ${pkgs.wofi}/bin/wofi --insensitive --dmenu -W 100 -H 160 --location bottom_right -x -80 -y -40)
  #   if [[ $choice == "Lock" ]];then
  #     ${pkgs.swaylock}/bin/swaylock -c '#000000' --indicator-radius 100 --indicator-thickness 20 --show-failed-attempts
  #   elif [[ $choice == "Logout" ]];then
  #     pkill -KILL -u "$USER"
  #   elif [[ $choice == "Suspend" ]];then
  #     systemctl suspend
  #   elif [[ $choice == "Reboot" ]];then
  #     systemctl reboot
  #   elif [[ $choice == "Shutdown" ]];then
  #     systemctl poweroff
  #   fi
  # '';
  launch = "${pkgs.nwg-menu}/bin/nwg-menu";
  logout = "${pkgs.nwg-bar}/bin/nwg-bar";
in
{
  # imports = [
  #   ../../overlays/waybar-hyprland.nix
  # ];

  home.packages = with pkgs; [
    waybar
  ];

  programs.waybar = {
    enable = true;
    # If enabled, this will load waybar separately from sway's own config, leading to two bars being loaded
    systemd.enable = false;
    # ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}
    style = ''
      ${builtins.readFile ./waybar/waybar-angular.css}
    '';
    settings = {
      mainBar = {
        layer = "top";

        position = "bottom";

        modules-left = [
          "custom/launcher"
          "sway/workspaces"
          "sway/mode"
          "sway/window"
        ];
        modules-right = [
          "network"
          "backlight"
          "pulseaudio"
          "battery"
          "cpu"
          "memory"
          "temperature"
          "clock"
          "idle_inhibitor"
          "tray"
          "custom/power"
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

        "sway/workspaces" = {
          all-outputs = true;
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
          format = "{icon} {capacity}%";
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

        tray ={
          icon-size = 18;
          spacing = 10;
        };

        clock = {
          format = "{:%I:%M %p   %m/%d/%Y}";
        };

        cpu = {
          interval = 15;
          format = " {}%";
          max-length = 10;
        };

        memory = {
          interval = 30;
          format = " {}%";
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
          format = "ꅾ";
          on-click = launch;
          on-click-right = "pkill wofi";
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


