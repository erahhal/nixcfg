## @TODOS
## - If there is no settings.json, dms needs to be restarted twice to pick up the settings, as it creates it during the startup process.
## - Get settings sync working - it doesn't always work
## - Figure out how to have multiple control centers with different configs
## - Figure out how to get automatic night mode working to replace gammastep
## - What's going on with the session below, and how does it different from config/settings?
##   - Appears to be for wallpaper, not sure why it's separate from config
## - Figure out how to get launcher to run arbitrary executables - seems to only run .desktop files

{ pkgs, config, lib, osConfig, ... }:
let
  wallpaperPath = if osConfig.hostParams.desktop.wallpaper != null
    then toString osConfig.hostParams.desktop.wallpaper
    else null;

  dms-command-runner = pkgs.fetchFromGitHub {
    owner = "devnullvoid";
    repo = "dms-command-runner";
    rev = "d89a09413e2fc041089b595a06c0fb316b12e17a";
    hash = "sha256-tXqDRVp1VhyD1WylW83mO4aYFmVg/NV6Z/toHmb5Tn8=";
  };

  nag-graphical = pkgs.callPackage ../../pkgs/nag-graphical {};

  # Default plugin settings - merged into plugin_settings.json on activation
  defaultPluginSettings = {
    commandRunner = {
      enabled = true;
      noTrigger = true;
      trigger = ">";
      terminal = "foot";
      execFlag = "-e";
    };
  };

  # Script to lock screen then suspend (simulates DMS lockBeforeSuspend)
  dms-suspend = pkgs.writeShellScript "dms-suspend" ''
    dms ipc call lock lock
    sleep 0.5
    systemctl suspend
  '';

  # Confirmation dialogs for power actions
  reboot-dialog = pkgs.writeShellScript "dms-reboot-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Reboot?' 'systemctl reboot'
  '';

  suspend-dialog = pkgs.writeShellScript "dms-suspend-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Suspend?' '${dms-suspend}'
  '';

  power-off-dialog = pkgs.writeShellScript "dms-power-off-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Power off?' 'systemctl poweroff'
  '';

  exit-dialog = pkgs.writeShellScript "dms-exit-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Exit Niri?' 'niri msg action quit'
  '';

  # Helper function to create JSON sync activation scripts
  # Merges default file into target file, preserving user-added keys
  mkJsonSyncScript = { dir, defaultFile, targetFile, name }:
    lib.hm.dag.entryAfter ["linkGeneration"] ''
      DIR="${dir}"
      DEFAULT="$DIR/${defaultFile}"
      TARGET="$DIR/${targetFile}"

      if [ -f "$DEFAULT" ]; then
        mkdir -p "$DIR"
        if [ -f "$TARGET" ]; then
          if ${pkgs.jq}/bin/jq -S -s '.[0] * .[1]' "$TARGET" "$DEFAULT" > "$TARGET.tmp" 2>/dev/null; then
            mv "$TARGET.tmp" "$TARGET"
          else
            rm -f "$TARGET.tmp"
            echo "Warning: Failed to merge DMS ${name}, keeping existing ${targetFile}"
          fi
        else
          cp "$DEFAULT" "$TARGET"
        fi
      fi
    '';
in
{
  home.file."Wallpaper".source = ../../wallpapers;

  # Add PATH and Qt theme to dms systemd service
  systemd.user.services.dms.Service = {
    Environment = [
      "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    ];
    # Inherit environment for icon theme discovery and loginctl integration
    PassEnvironment = [
      "QT_QPA_PLATFORMTHEME"
      "XDG_DATA_DIRS"
      "XCURSOR_SIZE"
      "XCURSOR_THEME"
      # Required for loginctl lock integration
      "XDG_SESSION_ID"
    ];
  };

  # Sync DMS JSON config files on activation
  home.activation.dmsSettingsSync = mkJsonSyncScript {
    dir = "${config.xdg.configHome}/DankMaterialShell";
    defaultFile = "default-settings.json";
    targetFile = "settings.json";
    name = "settings";
  };

  home.activation.dmsSessionSync = mkJsonSyncScript {
    dir = "${config.xdg.stateHome}/DankMaterialShell";
    defaultFile = "default-session.json";
    targetFile = "session.json";
    name = "session";
  };

  home.activation.dmsPluginSettingsSync = mkJsonSyncScript {
    dir = "${config.xdg.configHome}/DankMaterialShell";
    defaultFile = "default-plugin_settings.json";
    targetFile = "plugin_settings.json";
    name = "plugin settings";
  };

  # Niri keybinding overrides for DMS
  xdg.configFile."niri/dms.kdl".text = ''
    binds {
      // DMS Application Launcher and Notification Center
      // Temporarily disabled as it doesn't run arbitray executables
      Mod+P hotkey-overlay-title="DMS Application Launcher" { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
      Mod+N hotkey-overlay-title="DMS Notification Center" { spawn "dms" "ipc" "call" "notifications" "toggle"; }

      // Color picker - use DMS color picker (auto-copy hex to clipboard)
      Mod+A hotkey-overlay-title="DMS Color Picker" { spawn "dms" "color" "pick" "--hex" "-a"; }

      // Screenshots - use DMS screenshot (opens in editor for annotation)
      Ctrl+Shift+3 hotkey-overlay-title="Capture Screen" { spawn "dms" "ipc" "call" "niri" "screenshotScreen"; }
      Ctrl+Shift+4 hotkey-overlay-title="Capture Selection" { spawn "dms" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Shift+5 hotkey-overlay-title="Capture Window" { spawn "dms" "ipc" "call" "niri" "screenshotWindow"; }

      // Lock - use DMS lock instead of hyprlock
      Mod+X hotkey-overlay-title="Lock the Screen: DMS" allow-when-locked=true { spawn "dms" "ipc" "call" "lock" "lock"; }

      // Power actions - with confirmation dialogs
      Mod+Shift+E hotkey-overlay-title="Exit Niri" { spawn "${exit-dialog}"; }
      Mod+Shift+R hotkey-overlay-title="Reboot" { spawn "${reboot-dialog}"; }
      Mod+Shift+S hotkey-overlay-title="Suspend" { spawn "${suspend-dialog}"; }
      Mod+Shift+P hotkey-overlay-title="Power Off" { spawn "${power-off-dialog}"; }

      // Ctrl+Alt+Delete - quit niri (shows confirmation)
      Ctrl+Alt+Delete { quit; }
    }

    switch-events {
      // Lid close - lock then suspend
      lid-close { spawn "${dms-suspend}"; }
    }
  '';

  # Include DMS keybindings in niri config
  xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
    include "dms.kdl"
  '';

  # Default plugin settings file - merged into plugin_settings.json on activation
  xdg.configFile."DankMaterialShell/default-plugin_settings.json".text =
    builtins.toJSON defaultPluginSettings;

  programs.dankMaterialShell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Plugins (settings are in defaultPluginSettings, synced via activation script)
    plugins = {
      CommandRunner = {
        enable = true;
        src = dms-command-runner;
      };
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
          "controlCenterButton"
          "systemTray"
          "clipboard"
          "cpuUsage"
          "memUsage"
          "battery"
          "weather"
          "clock"
          "idleInhibitor"
          "notificationButton"
        ];

        ## Layout
        position = 1;  # 0=top, 1=bottom, 2=left, 3=right
        spacing = 3;
        bottomGap = 1;
      }];

      ## Displays
      screenPreferences = ["all"];
      showOnLastDisplay = true;

      ## Layout
      innerPadding = 4;
      popupGapsAuto = true;
      popupGapsManual = 4;

      ## Style
      matugenTemplateFirefox = false; # disables creating firefox.css file on manual config change. What are the ramifications?
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

      ## Power/Lock screen
      acMonitorTimeout = 300;
      acLockTimeout = 300;
      lockBeforeSuspend = true;
      lockScreenShowPowerActions = true;
      loginctlLockIntegration = true;
      fadeToLockEnabled = true;
      fadeToLockGracePeriod = 5;

      ### Widgets

      ## Clock
      use24HourClock = false;

      ## Weather
      weatherEnabled = true;
      useAutoLocation = true;
      weatherLocation = "Los Angeles, CA";
      weatherCoordinates = "34.1509, 118.4487";
      useFahrenheit = true;

      ## Night Mode
      nightModeEnabled = true;

      ## Control Center
      controlCenterShowNetworkIcon = true;
      controlCenterShowBluetoothIcon = true;
      controlCenterShowAudioIcon = true;
      controlCenterShowVpnIcon = true;
      controlCenterShowBrightnessIcon = true;
      controlCenterShowMicIcon = true;
      controlCenterShowBatteryIcon = false;
      controlCenterShowPrinterIcon = false;
      controlCenterWidgets = [
        {
          id = "volumeSlider";
          enabled = true;
        }
        {
          id = "audioOutput";
          enabled = true;
        }
        {
          id = "audioInput";
          enabled = true;
        }
        {
          id = "brightnessSlider";
          enabled = true;
        }
        {
          id = "wifi";
          enabled = true;
        }
        {
          id = "bluetooth";
          enabled = true;
        }
        {
          id = "nightMode";
          enabled = true;
        }
        {
          id = "darkMode";
          enabled = true;
        }
      ];

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

    # Default session (wallpaper path, etc.)
    default.session = lib.mkIf (wallpaperPath != null) {
      wallpaperPath = wallpaperPath;
    };
  };
}
