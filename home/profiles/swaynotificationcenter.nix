{ inputs, pkgs, ...}:
let
  startSNC = pkgs.writeShellScript "startsnc.sh" ''
    ${pkgs.procps}/bin/pkill swaync
    ${pkgs.swaynotificationcenter}/bin/swaync
  '';
  hyprlockCommand = pkgs.callPackage ../../pkgs/hyprlock-command { inputs = inputs; pkgs = pkgs; };
in
{
  home.packages = with pkgs; [
    swaynotificationcenter
  ];

  systemd.user.services.swaynotificationcenter = {
    Unit = {
      Description = "Sway Notification Center daemon";
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${startSNC}";
      RestartSec = 5;
      Restart = "always";
    };
  };


  ## How to execute scripts with SwayNC
  # "scripts": {
  #   "example-action-script": {
  #     "exec": "echo 'Do something actionable!'",
  #     "urgency": "Normal",
  #     "run-on": "action"
  #   }
  # },
  xdg.configFile."swaync/config.json".text = ''
    {
      "$schema": "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json",
      "positionX": "right",
      "positionY": "top",
      "layer": "overlay",
      "control-center-layer": "top",
      "layer-shell": true,
      "cssPriority": "user",
      "control-center-margin-top": 0,
      "control-center-margin-bottom": 0,
      "control-center-margin-right": 0,
      "control-center-margin-left": 0,
      "notification-2fa-action": true,
      "notification-inline-replies": false,
      "notification-icon-size": 64,
      "notification-body-image-height": 100,
      "notification-body-image-width": 200,
      "timeout": 10,
      "timeout-low": 5,
      "timeout-critical": 0,
      "fit-to-screen": true,
      "control-center-width": 500,
      "control-center-height": 600,
      "notification-window-width": 500,
      "keyboard-shortcuts": true,
      "image-visibility": "when-available",
      "transition-time": 200,
      "hide-on-clear": false,
      "hide-on-action": true,
      "script-fail-notify": true,
      "notification-visibility": {
        "example-name": {
          "state": "muted",
          "urgency": "Low",
          "app-name": "Spotify"
        }
      },
      "widgets": [
        "inhibitors",
        "title",
        "dnd",
        "notifications",
        "mpris",
        "volume",
        "backlight",
        "buttons-grid"
      ],
      "widget-config": {
        "inhibitors": {
          "text": "Inhibitors",
          "button-text": "Clear All",
          "clear-all-button": true
        },
        "title": {
          "text": "Notifications",
          "clear-all-button": true,
          "button-text": "Clear All"
        },
        "dnd": {
          "text": "Do Not Disturb"
        },
        "label": {
          "max-lines": 5,
          "text": "Label Text"
        },
        "mpris": {
          "image-size": 80,
          "image-radius": 10
        },
        "volume": {
          "label": "",
          "step": 5
        },
        "backlight": {
          "label": "󰃞",
          "step": 5
        },
        "buttons-grid": {
          "actions": [
            {
              "label": "",
              "command": "${pkgs.networkmanagerapplet}/bin/nm-connection-editor",
              "tooltip": "Network"
            },
            {
              "label": "",
              "command": "${pkgs.blueman}/bin/blueman-manager",
              "tooltip": "Bluetooth"
            },
            {
              "label": "󰂛",
              "command": "${pkgs.swaynotificationcenter}/bin/swaync-client -d",
              "type": "toggle",
              "tooltip": "DND"
            },
            {
              "label": "󰷛",
              "command": "${hyprlockCommand}",
              "tooltip": "Lock"
            },
            {
              "label": "󰜉",
              "command": "systemctl reboot",
              "tooltip": "Reboot"
            },
            {
              "label": "⏻",
              "command": "systemctl poweroff",
              "tooltip": "Power Off"
            }
          ]
        }
      }
    }
  '';

  xdg.configFile."swaync/style.css".source = "${pkgs.swaynotificationcenter}/etc/xdg/saync/style.css";
}
