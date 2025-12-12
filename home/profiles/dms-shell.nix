{ inputs, pkgs, config, lib, ... }:
{
  home.file."Wallpaper".source = ../../wallpapers;

  # Add PATH and Qt theme to dms systemd service
  systemd.user.services.dms.Service = {
    Environment = [
      "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    ];
    # Inherit environment for icon theme discovery
    PassEnvironment = [
      "QT_QPA_PLATFORMTHEME"
      "XDG_DATA_DIRS"
      "XCURSOR_SIZE"
      "XCURSOR_THEME"
    ];
  };

  # Sync default-settings.json to settings.json on activation
  home.activation.dmsSettingsSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DMS_CONFIG_DIR="${config.xdg.configHome}/DankMaterialShell"
    DEFAULT_SETTINGS="$DMS_CONFIG_DIR/default-settings.json"
    SETTINGS="$DMS_CONFIG_DIR/settings.json"

    if [ -f "$DEFAULT_SETTINGS" ]; then
      mkdir -p "$DMS_CONFIG_DIR"
      if [ -f "$SETTINGS" ]; then
        # Deep merge with special handling for barConfigs array (merge by id)
        ${pkgs.jq}/bin/jq -s '
          # Function to merge barConfigs arrays by id
          def merge_bar_configs(existing; defaults):
            [existing[], defaults[]]
            | group_by(.id)
            | map(reduce .[] as $item ({}; . * $item));

          # Merge top-level, with special handling for barConfigs
          .[0] * .[1] * {
            barConfigs: merge_bar_configs(.[0].barConfigs // []; .[1].barConfigs // [])
          }
        ' "$SETTINGS" "$DEFAULT_SETTINGS" > "$SETTINGS.tmp"
        cat "$SETTINGS.tmp" > "$SETTINGS"
        rm "$SETTINGS.tmp"
      else
        # No settings.json exists, just copy default-settings.json
        cat "$DEFAULT_SETTINGS" > "$SETTINGS"
      fi
    fi
  '';

  # Niri keybinding overrides for DMS
  xdg.configFile."niri/dms.kdl".text = ''
    binds {
      Mod+P hotkey-overlay-title="DMS Application Launcher" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
      Mod+N hotkey-overlay-title="DMS Notification Center" { spawn "dms" "ipc" "call" "notifications" "toggle"; }
    }
  '';

  # Include DMS keybindings in niri config
  xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
    include "dms.kdl"
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

        ## Widgets
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

        ## Layout
        position = 1;  # 0=top, 1=bottom, 2=left, 3=right
      }];

      ## Displays
      screenPreferences = ["all"];
      showOnLastDisplay = true;

      ## Layout
      spacing = 3;
      innerPadding = 4;
      bottomGap = 1;
      popupGapsAuto = true;
      popupGapsManual = 4;

      ## Style
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

      ## Behavior
      visible = true;
      autoHide = false;
      autoHideDelay = 250;
      openOnOverview = false;

      # On Screen Display
      osdPowerProfileEnabled = true;

      ## Workspaces
      showWorkspaceIndex = true;
      showWorkspacePadding = true;
      showWorkspaceApps = true;
      showOccupiedWorkspacesOnly = true;

      ## Dock
      showDock = false;
      dockAutoHide = true;
      dockGroupByApp = false;
      dockOpenOnOverview = true;

      ## Animation
      customAnimationDuration = 100;

      ## Clock
      use24HourClock = false;

      ## Weather
      weatherEnabled = true;
      useAutoLocation = true;
      weatherLocation = "Los Angeles, CA";
      weatherCoordinates = "34.1509, 118.4487";
      useFahrenheit = true;

      ## Theme
      currentThemeName = "custom";
      customThemeFile = pkgs.writeTextFile {
        name = "theme_tokyonight.json";
        text = ''
          {
            "dark": {
              "name": "Tokyo Night night",
              "primary": "#7aa2f7",
              "primaryText": "#16161e",
              "primaryContainer": "#7dcfff",
              "secondary": "#bb9af7",
              "surface": "#1a1b26",
              "surfaceText": "#73daca",
              "surfaceVariant": "#2f3549",
              "surfaceVariantText": "#cbccd1",
              "surfaceTint": "#7aa2f7",
              "background": "#16161e",
              "backgroundText": "#d5d6db",
              "outline": "#787c99",
              "surfaceContainer": "#2f3549",
              "surfaceContainerHigh": "#444b6a",
              "error": "#f7768e",
              "warning": "#ff9e64",
              "info": "#7dcfff"
          },
            "light": {
              "name": "Tokyo Night day",
              "primary": "#2e7de9",
              "primaryText": "#d0d5e3",
              "primaryContainer": "#007197",
              "secondary": "#9854f1",
              "surface": "#e1e2e7",
              "surfaceText": "#387068",
              "surfaceVariant": "#c4c8da",
              "surfaceVariantText": "#1a1b26",
              "surfaceTint": "#2e7de9",
              "background": "#cbccd1",
              "backgroundText": "#1a1b26",
              "outline": "#4c505e",
              "surfaceContainer": "#dfe0e5",
              "surfaceContainerHigh": "#9699a3",
              "error": "#f52a65",
              "warning": "#b15c00",
              "info": "#007197"
            }
          }
        '';
      };
    };
  };
}
