{  pkgs, ... }:
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      alsaSupport = true;
      pulseSupport = true;
      iwSupport = true;
      githubSupport = true;
    };
    script = "polybar bottom &";
    settings = {
      "colors" = {
        grey-dark = "#353a3c";
        black = "#000";
        white = "#fff";
        grey = "#64727d";
        orange = "#f0932b";
        red = "#eb4d4b";
        violet = "#9b59b6";
        green = "#2ecc71";
        blue = "#2980b9";
        yellow = "#f1c40f";
        yellow-dark = "#675407";
        red-orange = "#f53c3c";
        blue-grey = "#90b1b1";
      };
      "bar/laptop" = {
        dpi = 130;
        height = 48;
        tray-maxsize = 40;
        bottom = true;
        monitor = "\${env:MONITOR:}";
        fixed-center = true;
        modules-center = "window";
        modules-left = "i3";
        modules-right = "volume wireless wired cpu memory temperature battery date";
        tray-position = "right";
        tray-background = "\${colors.blue}";
        tray-padding = "2";
        font = [ "Roboto:size=14;3" "Helvetica:size=14;3" "Arial:size=14;3" "Iosevka Term:size=34;9"];
        # font = [ "RobotoMono Nerd Font:size=14;3"];
        background = "\${colors.grey-dark}";
        foreground = "\${colors.white}";
      };
      "bar/bottom" = {
        tray-maxsize = 34;
        height = 36;
        bottom = true;
        monitor = "\${env:MONITOR:}";
        fixed-center = true;
        modules-center = "window";
        modules-left = "i3";
        modules-right = "volume wireless wired cpu memory temperature battery date";
        tray-position = "right";
        tray-background = "\${colors.blue}";
        tray-padding = "2";
        font = [ "Roboto:size=14;3" "Helvetica:size=14;3" "Arial:size=14;3" "Iosevka Term:size=34;9"];
        # font = [ "RobotoMono Nerd Font:size=14;3"];
        background = "\${colors.grey-dark}";
        foreground = "\${colors.white}";
      };
      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        enable-click = true;
        enable-scroll = true;
        wrapping-scroll = false;
        label-focused = "%index%";
        label-focused-padding = "2";
        label-focused-background = "\${colors.grey}";
        label-focused-foreground = "\${colors.white}";
        label-unfocused = "%index%";
        label-unfocused-padding = "2";
        label-unfocused-foreground = "\${colors.white}";
        label-visible = "%index%";
        label-visible-padding = "2";
        label-visible-foreground = "\${colors.white}";
        label-urgent = "%index%";
        label-urgent-padding = "2";
        label-urgent-foreground = "\${colors.white}";
      };
      "module/window" = {
        type = "internal/xwindow";
        label = "%title%";
        label-maxlen = 50;
        format = "<label>";
        format-padding = "2";
        format-foreground = "\${colors.white}";
      };
      "module/volume" = {
        type = "internal/pulseaudio";
        ramp-volume = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        label-volume = "VOLUME %percentage%%";
        format-volume = "<label-volume> <ramp-volume>";
        format-volume-background = "\${colors.yellow}";
        format-volume-foreground = "\${colors.black}";
        format-volume-padding = "2";
        label-muted = "MUTED ";
        format-muted = "<label-muted>";
        format-muted-background = "\${colors.yellow-dark}";
        format-muted-foreground = "\${colors.black}";
        format-muted-padding = "2";
        click-right = "pavucontrol &amp;";
      };
      "module/wireless" = {
        type = "internal/network";
        interface = "wlp0s20f3";
        interval = 3.0;
        accumulate-stats = true;
        label-connected = "%essid% ↓%downspeed:5:9% ↑%upspeed:5:9%";
        ramp-signal = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        format-connected = "<label-connected> <ramp-signal>";
        format-connected-background = "\${colors.blue}";
        format-connected-foreground = "\${colors.white}";
        format-connected-padding = "2";
        # format-disconnected = "Disconnected ⚠";
        # format-disconnected-background = "\${colors.red-orange}";
        # format-disconnected-foreground = "\${colors.black}";
        # format-disconnected-padding = "2";
      };
      "module/wired" = {
        type = "internal/network";
        interface = "enp12s0";
        interval = 3.0;
        accumulate-stats = true;
        label-connected = "%ifname% ↓%downspeed:5:9% ↑%upspeed:5:9%";
        format-connected = "<label-connected>";
        format-connected-background = "\${colors.blue}";
        format-connected-foreground = "\${colors.white}";
        format-connected-padding = "2";
      };
      "module/cpu" = {
        type = "internal/cpu";
        interval = 0.5;
        # format = "<label> <ramp-coreload>";
        format = "<label>";
        label = " %percentage%%";
        ramp-coreload = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        ramp-coreload-spacing = 1;
        format-background = "\${colors.green}";
        format-foreground = "\${colors.black}";
        format-padding = "2";
      };
      "module/memory" = {
        type = "internal/memory";
        interval = 3;
        format = "<label> <ramp-used>";
        label = "MEM %percentage_used%%";
        ramp-used = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        format-background = "\${colors.violet}";
        format-foreground = "\${colors.white}";
        format-padding = "2";
      };
      "module/temperature" = {
        type = "internal/temperature";
        interval = 1;
        hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon6/temp1_input";
        base-temperature = 20;
        warn-temperature = 80;
        units = true;
        label = "TEMP %temperature-c%";
        label-warn = "TEMP %temperature-c%";
        format = "<label>";
        format-background = "\${colors.orange}";
        format-foreground = "\${colors.white}";
        format-padding = "2";
        format-warn = "<label-warn>";
        format-warn-background = "\${colors.red}";
        format-warn-foreground = "\${colors.white}";
        format-warn-padding = "2";
      };
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "AC";
        ramp-capacity = [ "" "" "" "" "" ];
        format-charging = "<label-charging> <ramp-capacity>";
        format-charging-background = "\${colors.white}";
        format-charging-foreground = "\${colors.black}";
        format-charging-padding = "2";
        format-discharging = "<label-discharging> <ramp-capacity>";
        format-discharging-background = "\${colors.white}";
        format-discharging-foreground = "\${colors.black}";
        format-discharging-padding = "2";
        format-full = "<label-full> <ramp-capacity>";
        format-full-background = "\${colors.white}";
        format-full-foreground = "\${colors.black}";
        format-full-padding = "2";
        font-scale = 0.75;
      };
      "module/date" = {
        type = "internal/date";
        label = "%date% | %time%";
        date = "%Y-%m-%d%";
        time = "%H:%M:%S";
        interval = "1.0";
        format = "<label>";
        format-background = "\${colors.grey}";
        format-foreground = "\${colors.white}";
        format-padding = "2";
      };
    };
  };
}

