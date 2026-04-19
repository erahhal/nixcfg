{ osConfig, config, lib, pkgs, ... }:
let
  colors = config.lib.stylixScheme or config.lib.stylix.colors;
  cursorName = osConfig.stylix.cursor.name;
  cursorSize = toString osConfig.stylix.cursor.size;
  fontName = osConfig.stylix.fonts.sansSerif.name;
  fontSize = toString osConfig.stylix.fonts.sizes.desktop;

  # Convert base16 hex to R,G,B for kcalcrc
  hexToRGB = hex: let
    h = lib.strings.toLower hex;
    hexVal = c:
      if c == "0" then 0 else if c == "1" then 1 else if c == "2" then 2
      else if c == "3" then 3 else if c == "4" then 4 else if c == "5" then 5
      else if c == "6" then 6 else if c == "7" then 7 else if c == "8" then 8
      else if c == "9" then 9 else if c == "a" then 10 else if c == "b" then 11
      else if c == "c" then 12 else if c == "d" then 13 else if c == "e" then 14
      else 15;
    r = (hexVal (builtins.substring 0 1 h)) * 16 + (hexVal (builtins.substring 1 1 h));
    g = (hexVal (builtins.substring 2 1 h)) * 16 + (hexVal (builtins.substring 3 1 h));
    b = (hexVal (builtins.substring 4 1 h)) * 16 + (hexVal (builtins.substring 5 1 h));
  in "${toString r},${toString g},${toString b}";

  bgRGB = hexToRGB colors.base00;
  fgRGB = hexToRGB colors.base05;

  isDark = osConfig.stylix.polarity == "dark";

  gtkThemeName = if isDark then "Tokyonight-Dark" else "Arc-Light";
  iconThemeName = if isDark then "breeze-dark" else "Adwaita";

  toggle-theme-script = pkgs.writeShellScriptBin "toggle-theme-script" ''
    set -euo pipefail

    THEME_DIR="$HOME/.local/share/theme-toggle"
    PATHS_FILE="$THEME_DIR/paths.sh"

    if [ ! -f "$PATHS_FILE" ]; then
      echo "ERROR: No theme paths saved. Rebuild first." >&2
      exit 1
    fi

    # Lock to prevent concurrent toggles (rapid key presses)
    LOCK_FILE="$THEME_DIR/toggle.lock"
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
      echo "Toggle already in progress, skipping." >&2
      exit 0
    fi
    trap 'rm -f "$LOCK_FILE"' EXIT

    source "$PATHS_FILE"

    # Detect current mode from actual symlink state (not a mode file that can go stale)
    # Check a known file — if it points into DARK_HOME_FILES, we're in dark mode
    PROBE_FILE="$HOME/.config/foot/foot.ini"
    PROBE_TARGET="$(readlink "$PROBE_FILE" 2>/dev/null || true)"
    if [[ "$PROBE_TARGET" == "$DARK_HOME_FILES"* ]]; then
      CURRENT_MODE="dark"
    elif [[ "$PROBE_TARGET" == "$LIGHT_HOME_FILES"* ]]; then
      CURRENT_MODE="light"
    else
      # Symlink points to an unknown home-files (e.g., stale from old build) — assume dark
      CURRENT_MODE="dark"
    fi

    if [ "$CURRENT_MODE" = "dark" ]; then
      TARGET_MODE="light"
      OLD_HOME_FILES="$DARK_HOME_FILES"
      NEW_HOME_FILES="$LIGHT_HOME_FILES"
      NEW_DCONF_INI="$LIGHT_DCONF_INI"
    else
      TARGET_MODE="dark"
      OLD_HOME_FILES="$LIGHT_HOME_FILES"
      NEW_HOME_FILES="$DARK_HOME_FILES"
      NEW_DCONF_INI="$DARK_DCONF_INI"
    fi

    if [ -z "$NEW_HOME_FILES" ] || [ ! -d "$NEW_HOME_FILES" ]; then
      echo "ERROR: Target home-files not found: $NEW_HOME_FILES" >&2
      exit 1
    fi

    echo "Switching to $TARGET_MODE mode"

    # Phase 1: Swap symlinks
    # Use process substitution (not pipe) so loop runs in main shell and set -e works correctly
    # Repoint all HM-managed symlinks from old to new home-files
    while IFS= read -r rel_path; do
      target_path="$HOME/$rel_path"
      if [ -L "$target_path" ]; then
        current_target="$(readlink "$target_path" 2>/dev/null || true)"
        case "$current_target" in
          /nix/store/*-home-manager-files/*)
            ln -Tsf "$NEW_HOME_FILES/$rel_path" "$target_path"
            ;;
        esac
      fi
    done < <(find "$NEW_HOME_FILES" \( -type f -or -type l \) -printf '%P\n')

    # Handle files only in OLD (remove orphan symlinks)
    while IFS= read -r rel_path; do
      if [ ! -e "$NEW_HOME_FILES/$rel_path" ]; then
        target_path="$HOME/$rel_path"
        if [ -L "$target_path" ]; then
          current_target="$(readlink "$target_path" 2>/dev/null || true)"
          case "$current_target" in
            /nix/store/*-home-manager-files/*)
              rm -f "$target_path"
              ;;
          esac
        fi
      fi
    done < <(find "$OLD_HOME_FILES" \( -type f -or -type l \) -printf '%P\n')

    # Handle files only in NEW (create new symlinks)
    while IFS= read -r rel_path; do
      if [ ! -e "$OLD_HOME_FILES/$rel_path" ]; then
        target_path="$HOME/$rel_path"
        mkdir -p "$(dirname "$target_path")"
        ln -Tsf "$NEW_HOME_FILES/$rel_path" "$target_path"
      fi
    done < <(find "$NEW_HOME_FILES" \( -type f -or -type l \) -printf '%P\n')

    # Phase 2: Switch DMS BEFORE dconf — avoids race with DMS auto-detecting dconf change
    if [ -x /run/current-system/sw/bin/dms ]; then
      /run/current-system/sw/bin/dms ipc call theme "$TARGET_MODE" 2>/dev/null || true
    fi

    # Phase 3: Update dconf (triggers GTK/portal apps; DMS already switched above)
    if [ -n "$NEW_DCONF_INI" ] && [ -f "$NEW_DCONF_INI" ]; then
      dconf load / < "$NEW_DCONF_INI"
    fi
    # Phase 4: Reload applications
    pkill -HUP xsettingsd 2>/dev/null || true

    # Reload tmux — sources .tmux.conf which triggers gpakosz's _apply_theme()
    # to reprocess the theme variables from the newly-swapped .tmux.conf.local.
    # Sleep after to let _apply_theme (runs in background via &) finish before
    # releasing the flock — prevents a rapid second toggle from being overwritten.
    if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
      tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
      sleep 1
    fi

    if ${pkgs.procps}/bin/pidof niri > /dev/null 2>&1; then
      systemctl --user restart waybar 2>/dev/null || true
    fi

    # Phase 5: Verify DMS switched (retry if dconf auto-detection reverted it)
    if [ -x /run/current-system/sw/bin/dms ]; then
      sleep 0.3
      CURRENT_DMS="$(/run/current-system/sw/bin/dms ipc call theme getMode 2>/dev/null || echo "")"
      if [ "$CURRENT_DMS" != "$TARGET_MODE" ]; then
        /run/current-system/sw/bin/dms ipc call theme "$TARGET_MODE" 2>/dev/null || true
      fi
    fi

    # Fix Chromium to follow system theme — only works when Chromium is closed
    # (Chromium overwrites Preferences while running; Brave doesn't need this)
    for prefs in "$HOME/.config/chromium/Default/Preferences"; do
      if [ -f "$prefs" ] && ! ${pkgs.procps}/bin/pidof chromium > /dev/null 2>&1; then
        ${pkgs.python3}/bin/python3 -c "
import json
path = '$prefs'
with open(path) as f:
    d = json.load(f)
# Enable system theme following
bt = d.setdefault('browser', {}).setdefault('theme', {})
bt['follows_system_colors'] = True
bt['color_scheme2'] = 0
# Remove any stale theme extension
et = d.setdefault('extensions', {}).setdefault('theme', {})
et.pop('id', None)
et.pop('pack', None)
with open(path, 'w') as f:
    json.dump(d, f)
" 2>/dev/null || true
      fi
    done

    # Fix Stylix light mode: 'default' → 'prefer-light' so portal reports value 2, not 0.
    # Done LAST so nothing can revert it (dconf load, DMS, xsettingsd all finished).
    if [ "$TARGET_MODE" = "light" ]; then
      sleep 0.2
      dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    fi

    echo "Theme switched to $TARGET_MODE"
  '';

  runtime-paths = lib.makeBinPath [
    pkgs.coreutils
    pkgs.dconf
    pkgs.findutils
    pkgs.procps
    pkgs.systemd
    pkgs.tmux
    pkgs.waybar
  ];

  toggle-theme = pkgs.stdenv.mkDerivation {
    name = "toggle-theme";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      install -Dm755 ${toggle-theme-script}/bin/toggle-theme-script $out/bin/toggle-theme
      wrapProgram $out/bin/toggle-theme \
        --suffix PATH : ${runtime-paths}
    '';
  };
in
{
  # Disable Stylix for apps with custom config management
  stylix.targets.vscode.enable = false;

  # --- Xresources ---
  # Stylix handles colors, cursor, and fonts. Only add host-specific DPI override.
  xresources.extraConfig = if osConfig.hostParams.desktop.disableXwaylandScaling then ''
    Xft.dpi: ${toString osConfig.hostParams.desktop.dpi}
  '' else "";
  home.file.".Xdefaults".text = if osConfig.hostParams.desktop.disableXwaylandScaling then ''
    Xft.dpi: ${toString osConfig.hostParams.desktop.dpi}
  '' else "";

  # --- xsettingsd (driven by Stylix colors) ---
  services.xsettingsd = {
    enable = true;
    settings = {
      "Gdk/UnscaledDPI" = 196608;
      "Gdk/WindowScalingFactor" = 1;
      "Gtk/EnableAnimations" = 1;
      "Gtk/DecorationLayout" = ":minimize,maximize,close";
      "Net/ThemeName" = gtkThemeName;
      "Gtk/PrimaryButtonWarpsSlider" = 1;
      "Gtk/ToolbarStyle" = 3;
      "Gtk/MenuImages" = 1;
      "Gtk/ButtonImages" = 1;
      "Net/CursorBlinkTime" = 1000;
      "Net/CursorBlink" = 1;
      "Gtk/CursorThemeSize" = if osConfig.hostParams.desktop.defaultSession == "none+i3" then 48 else 24;
      "Gtk/CursorThemeName" = cursorName;
      "Net/IconThemeName" = iconThemeName;
      "Gtk/FontName" = "${fontName},  ${fontSize}";
    };
  };

  xdg.configFile."xsettingsd/xsettingsd.conf".text = ''
    Gdk/UnscaledDPI 196608
    Gdk/WindowScalingFactor 1
    Gtk/EnableAnimations 1
    Gtk/DecorationLayout ":minimize,maximize,close"
    Net/ThemeName "${gtkThemeName}"
    Gtk/PrimaryButtonWarpsSlider 1
    Gtk/ToolbarStyle 3
    Gtk/MenuImages 1
    Gtk/ButtonImages 1
    Net/CursorBlinkTime 1000
    Net/CursorBlink 1
    Gtk/CursorThemeSize ${if osConfig.hostParams.desktop.defaultSession == "none+i3" then "48" else "24"}
    Gtk/CursorThemeName "${cursorName}"
    Net/IconThemeName "${iconThemeName}"
    Gtk/FontName "${fontName},  ${fontSize}"
  '';

  # --- KDE Calculator (driven by Stylix colors) ---
  xdg.configFile.kcalcrc.text = ''
    [Colors]
    BackColor=${bgRGB}
    ConstantsButtonsColor=${bgRGB}
    ConstantsFontsColor=${fgRGB}
    ForeColor=${fgRGB}
    FunctionButtonsColor=${bgRGB}
    FunctionFontsColor=${fgRGB}
    HexButtonsColor=${bgRGB}
    HexFontsColor=${fgRGB}
    MemoryButtonsColor=${bgRGB}
    MemoryFontsColor=${fgRGB}
    NumberButtonsColor=${bgRGB}
    NumberFontsColor=${fgRGB}
    OperationButtonsColor=${bgRGB}
    OperationFontsColor=${fgRGB}
    StatButtonsColor=${bgRGB}
    StatFontsColor=${fgRGB}

    [General]
    CalculatorMode=science
  '';

  # --- lsd colors (custom theme for light mode readability) ---
  xdg.configFile."lsd/config.yaml".text = ''
    color:
      theme: custom
  '';

  xdg.configFile."lsd/colors.yaml".text = ''
    user: 30
    group: 91
    permission:
      read: dark_green
      write: dark_yellow
      exec: dark_red
      exec-sticky: 5
      no-access: 245
      octal: 6
      acl: dark_cyan
      context: cyan
    date:
      hour-old: 40
      day-old: 42
      older: 36
    size:
      none: 245
      small: 59
      medium: 89
      large: 125
    inode:
      valid: 13
      invalid: 245
    links:
      valid: 43
      invalid: 85
    tree-edge: 245
    git-status:
      default: 245
      unmodified: 245
      ignored: 245
      new-in-index: dark_green
      new-in-workdir: dark_green
      typechange: dark_yellow
      deleted: dark_red
      renamed: dark_green
      modified: dark_yellow
      conflicted: dark_red
  '';

  # --- Powerlevel10k (not Stylix-managed) ---
  programs.zsh.plugins = [
    {
      name = "powerlevel10k-config";
      src = ./zsh-p10k-config;
      file = "p10k.zsh";
    }
  ];

  # --- Theme toggle ---
  home.file.".system-theme".text = if isDark then "dark-mode" else "light-mode";
  home.packages = [ toggle-theme ];

  # Save both dark and light home-files paths at activation time for fast toggle
  home.activation.saveThemePaths = lib.hm.dag.entryAfter ["linkGeneration"] ''
    THEME_DIR="$HOME/.local/share/theme-toggle"
    mkdir -p "$THEME_DIR"

    # $newGenPath is set by the HM activate script
    DARK_HOME_FILES="$(readlink -e "$newGenPath/home-files")"

    # Extract dconf INI path — match the specific hm-dconf.ini filename to avoid self-matching
    DARK_DCONF_INI="$(${pkgs.gnugrep}/bin/grep -oE '/nix/store/[a-z0-9]+-hm-dconf\.ini' "$newGenPath/activate" | head -1)"

    LIGHT_HOME_FILES=""
    LIGHT_DCONF_INI=""
    LIGHT_SPEC="$newGenPath/specialisation/light-mode"
    if [ -d "$LIGHT_SPEC" ]; then
      LIGHT_HOME_FILES="$(readlink -e "$LIGHT_SPEC/home-files")"
      LIGHT_DCONF_INI="$(${pkgs.gnugrep}/bin/grep -oE '/nix/store/[a-z0-9]+-hm-dconf\.ini' "$LIGHT_SPEC/activate" | head -1)"
    fi

    cat > "$THEME_DIR/paths.sh" <<PATHSEOF
    DARK_HOME_FILES="$DARK_HOME_FILES"
    LIGHT_HOME_FILES="$LIGHT_HOME_FILES"
    DARK_DCONF_INI="$DARK_DCONF_INI"
    LIGHT_DCONF_INI="$LIGHT_DCONF_INI"
    PATHSEOF

    # Mode detection is now based on actual symlink state, no mode file needed
  '';

  systemd.user.services.toggle-theme = {
    Unit.Description = "Theme toggler";
    Service = {
      Restart = "no";
      ExecStart = "${toggle-theme}/bin/toggle-theme";
    };
  };

  # ===================================================================
  # Light mode specialization
  # Only needs: Stylix polarity + p10k (everything else adapts via isDark)
  # ===================================================================
  specialisation.light-mode.configuration = {
    stylix = {
      polarity = lib.mkForce "light";
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/tokyo-night-light.yaml";
    };

    # Override stylix's default color-scheme. Stylix writes
    # color-scheme='default' for light polarity, which makes xdg-desktop-portal
    # emit org.freedesktop.appearance/color-scheme = uint32 0 ("no preference").
    # Chromium-based apps (Chromium, Brave, Signal, Joplin, etc.) receive that
    # intermediate signal first and stay on their old theme; the corrective
    # prefer-light signal that followed was ignored. Setting prefer-light
    # directly in the dconf database means dconf load emits exactly one
    # SettingChanged with uint32 2 and Electron apps flip cleanly.
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-light";

    # btop light theme (Stylix auto-themes dark; "paper" is a built-in light theme)
    xdg.configFile."btop/btop.conf".text = lib.mkAfter ''
      color_theme = "paper"
    '';

    # Light p10k with color overrides
    # Must include the p10k engine plugin (from base-user) since mkForce replaces the entire list
    programs.zsh.plugins = lib.mkForce [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = pkgs.writeTextFile {
          name = "p10k.zsh";
          destination = "/p10k.zsh";
          text = ((builtins.readFile ./zsh-p10k-config-light/p10k.zsh) + ''
            typeset -g POWERLEVEL9K_BACKGROUND=195
            typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=232
            typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=115
            typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=45
            typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=200
            typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=242
            typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=166
            typeset -g POWERLEVEL9K_ASDF_FOREGROUND=78
            typeset -g POWERLEVEL9K_RANGER_FOREGROUND=172
            typeset -g POWERLEVEL9K_MIDNIGHT_COMMANDER_FOREGROUND=172
          '');
        };
        file = "p10k.zsh";
      }
    ];
  };
}
