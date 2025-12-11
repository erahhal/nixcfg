{ inputs, pkgs, config, ... }:
{
  home.file."Wallpaper".source = ../../wallpapers;

  # Add PATH to dms systemd service so it can find qs
  systemd.user.services.dms.Service.Environment = [
    "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
  ];

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
        leftWidgets = ["launcherButton" "workspaceSwitcher" "focusedWindow"];
        centerWidgets = [];
        rightWidgets = ["music" "systemTray" "clipboard" "cpuUsage" "memUsage" "notificationButton" "battery" "controlCenterButton" "weather" "clock"];
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
