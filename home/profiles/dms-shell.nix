{ pkgs, config, lib, osConfig, ... }:
let
  wallpaperPath = if osConfig.hostParams.desktop.wallpaper != null
    then toString osConfig.hostParams.desktop.wallpaper
    else null;

  # Using bbedward's fork with PR #3 fix for high CPU usage
  # (switches from Item to QtObject to fix "graphical object not placed in scene" warnings)
  # TODO: Switch back to devnullvoid/dms-command-runner after PR #3 is merged
  dms-command-runner = pkgs.fetchFromGitHub {
    owner = "bbedward";
    repo = "dms-command-runner";
    rev = "8cbdae103d6304ad98fd4c579e82fad527ff3ebf";
    hash = "sha256-DWSWdP/gw6tp87u/0tkk4hL1oBtLWsVN6nbqLe4ClxM=";
  };

  dms-easyeffects = pkgs.fetchFromGitHub {
    owner = "jonkristian";
    repo = "dms-easyeffects";
    rev = "f50fdb7a110ddb90b7625bc143884fd773c3d5c7";
    hash = "sha256-q0Xp4RzHd0HgtUZEM4hIES6SDyN8R4lPgQe5aeLMh4c=";
  };

  dms-network-monitor = pkgs.callPackage ../../pkgs/dms-network-monitor {};

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
    networkMonitor = {
      enabled = true;
      checkInterval = 5;
      checkMethod = osConfig.hostParams.networking.networkMonitor.checkMethod;
      normalEndpoint = osConfig.hostParams.networking.networkMonitor.normalEndpoint;
      vpnCheckMethod = osConfig.hostParams.networking.networkMonitor.vpnCheckMethod;
      vpnEndpoint = osConfig.hostParams.networking.networkMonitor.vpnEndpoint;
      vpnInterfaces = ["tailscale0" "wg0" "tun0"];
    };
    easyEffects = {
      enabled = true;
    };
  };

  # Script to lock screen then suspend (simulates DMS lockBeforeSuspend)
  dms-suspend = pkgs.writeShellScript "dms-suspend" ''
    dms ipc call lock lock
    sleep 0.5
    systemctl suspend
  '';

  suspend-dialog = pkgs.writeShellScript "dms-suspend-dialog" ''
    ${nag-graphical}/bin/nag-graphical 'Suspend?' '${dms-suspend}'
  '';

  # Helper function to create JSON sync activation scripts
  # Merges default file into target file, preserving user-added keys
  mkJsonSyncScript = { dir, defaultFile, targetFile, name }: lib.hm.dag.entryAfter ["linkGeneration"] ''
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

  theme-tokyonight = pkgs.writeTextFile {
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
in
{
  imports = [
    ./easyeffects.nix
  ];

  home.file."Wallpaper".source = ../../wallpapers;

  # Add PATH and Qt theme to dms systemd service
  systemd.user.services.dms.Service = {
    Environment = [
      "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      # Use qt6ct platform theme for icon discovery
      # Set directly here instead of PassEnvironment to avoid stale systemd env issues
      "QT_QPA_PLATFORMTHEME=qt6ct"
    ];
    # Inherit environment for icon theme discovery and loginctl integration
    PassEnvironment = [
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
      Mod+Shift+S hotkey-overlay-title="Suspend" { spawn "${suspend-dialog}"; }

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

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Plugins (settings are in defaultPluginSettings, synced via activation script)
    plugins = {
      # Using bbedward's fork with PR #3 fix for graphics scene warnings
      CommandRunner = {
        enable = true;
        src = dms-command-runner;
      };
      NetworkMonitor = {
        enable = true;
        src = dms-network-monitor;
      };
      EasyEffects = {
        enable = true;
        src = dms-easyeffects;
      };
    };

    # Feature toggles (all default to true)
    enableSystemMonitoring = true;
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
          {
            id = "focusedWindow";
            enabled = true;
            ## Don't show app name, just title
            focusedWindowCompactMode = true;
          }
        ];
        centerWidgets = [];
        rightWidgets = [
          {
            id = "music";
            enabled = true;
          }
          {
            id = "easyEffects";
            enabled = true;
          }
          {
            id = "controlCenterButton";
            enabled = true;
            showAudioIcon = true;
            showBatteryIcon = false;
            showBluetoothIcon = false;
            showBrightnessIcon = false;
            showMicIcons = true;
            showNetworkIcon = false;
            showPrinterIcon = false;
            showVpnIcon = false;
          }
          {
            id = "systemTray";
            enabled = true;
          }
          {
            id = "clipboard";
            enabled = true;
          }
          {
            id = "cpuUsage";
            enabled = true;
          }
          {
            id = "memUsage";
            enabled = true;
          }
          {
            id = "battery";
            enabled = true;
          }
          {
            id = "weather";
            enabled = true;
          }
          {
            id = "controlCenterButton";
            enabled = true;
            showAudioIcon = false;
            showBatteryIcon = false;
            showBluetoothIcon = true;
            showBrightnessIcon = true;
            showMicIcon = false;
            showNetworkIcon = true;
            showPrinterIcon = false;
            showVpnIcon = false;
          }
          {
            id = "vpn";
            enabled = true;
          }
          {
            id = "networkMonitor";
            enabled = true;
          }
          {
            id = "clock";
            enabled = true;
          }
          {
            id = "idleInhibitor";
            enabled = true;
          }
          {
            id = "notificationButton";
            enabled = true;
          }
        ];

        ## Layout
        position = 1;  # 0=top, 1=bottom, 2=left, 3=right
        spacing = 3;
        bottomGap = 1;
        innerPadding = 8;  # Sets the bar size, strangely
        maximizeDetection = false;  # Don't remove gaps if the window is maxximized

        ## Behavior
        scrollYBehavior = "none";
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

      ## Icons
      dockIconsize = 24;

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

      ## Theme
      # currentThemeName = "custom";
      # customThemeFile = theme-tokyonight;
    };

    # Default session (wallpaper path, etc.)
    default.session = lib.mkIf (wallpaperPath != null) {
      wallpaperPath = wallpaperPath;
    };
  };
}
