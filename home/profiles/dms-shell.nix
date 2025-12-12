{ inputs, pkgs, config, lib, ... }:
{
  home.file."Wallpaper".source = ../../wallpapers;

  # Add PATH to dms systemd service so it can find qs
  systemd.user.services.dms.Service.Environment = [
    "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
  ];

  # Sync default-settings.json to settings.json on activation
  home.activation.dmsSettingsSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DMS_CONFIG_DIR="${config.xdg.configHome}/DankMaterialShell"
    DEFAULT_SETTINGS="$DMS_CONFIG_DIR/default-settings.json"
    SETTINGS="$DMS_CONFIG_DIR/settings.json"

    if [ -f "$DEFAULT_SETTINGS" ]; then
      mkdir -p "$DMS_CONFIG_DIR"
      if [ -f "$SETTINGS" ]; then
        # Deep merge: default-settings.json values override settings.json
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS" "$DEFAULT_SETTINGS" > "$SETTINGS.tmp"
        cat "$SETTINGS.tmp" > "$SETTINGS"
        rm "$SETTINGS.tmp"
      else
        # No settings.json exists, just copy default-settings.json
        cat "$DEFAULT_SETTINGS" > "$SETTINGS"
      fi
    fi
  '';

  programs.dankMaterialShell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    # Feature toggles (all default to true)
    enableSystemMonitoring = true;
    enableClipboard = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    # Default settings (only applied if settings.json doesn't exist)
    default.settings = {
      configVersion = 2;
      barConfigs = [{
        id = "default";
        name = "Main Bar";
        enabled = true;
        position = 1;  # 0=top, 1=bottom, 2=left, 3=right
        screenPreferences = ["all"];
        showOnLastDisplay = true;
        leftWidgets = [
          "launcherButton"
          "workspaceSwitcher"
          "focusedWindow"
        ];
        centerWidgets = [];
        rightWidgets = [
          "music"
          "systemTray"
          "clipboard"
          "cpuUsage"
          "memUsage"
          "battery"
          "controlCenterButton"
          "weather"
          "clock"
          "notificationButton"
        ];
        spacing = 4;
        innerPadding = 4;
        bottomGap = 0;
        transparency = 1;
        widgetTransparency = 1;
        squareCorners = false;
        noBackground = false;
        gothCornersEnabled = false;
        gothCornerRadiusOverride = false;
        gothCornerRadiusValue = 12;
        borderEnabled = false;
        borderColor = "surfaceText";
        borderOpacity = 1;
        borderThickness = 1;
        fontScale = 1;
        autoHide = false;
        autoHideDelay = 250;
        openOnOverview = false;
        visible = true;
        popupGapsAuto = true;
        popupGapsManual = 4;
      }];
    };
  };
}
