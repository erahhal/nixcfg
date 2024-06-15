args@{ pkgs, lib, inputs, hostParams, userParams, ... }:
let
xwayland_settings = ''
  Xcursor.size: ${if hostParams.defaultSession == "none+i3" then "48" else "24"}
  # Xcursor.theme: Adwaita
  Xcursor.theme: Bibata-Modern-Classic
  Xft.dpi: ${toString hostParams.dpi}
  xterm*background: #efefef
  xterm*faceName: Monospace
  xterm*faceSize: 12
  xterm*foreground: black
'';

# tmux cannot handle colors in the F ranges, e.g. #FNFNFN.
# They cause misalignment issues in the status bar for some unknown reason
# So using #EFEFEF for "white"
theme-colors = ''
  # default theme
  tmux_conf_theme_colour_1="#EFEFEF"    # white
  tmux_conf_theme_colour_2="#CFCFCF"    # gray
  tmux_conf_theme_colour_3="#353535"    # dark gray
  tmux_conf_theme_colour_4="#008CCC"    # light blue
  tmux_conf_theme_colour_5="#999900"    # yellow
  tmux_conf_theme_colour_6="#080808"    # dark gray
  tmux_conf_theme_colour_7="#e4e4e4"    # white
  tmux_conf_theme_colour_8="#EFEFEF"    # white
  tmux_conf_theme_colour_9="#999900"    # yellow
  tmux_conf_theme_colour_10="#AA007A"   # pink
  tmux_conf_theme_colour_11="#288800"   # green
  tmux_conf_theme_colour_12="#353535"   # dark gray
  tmux_conf_theme_colour_13="#1B1B1B"   # almost black
  tmux_conf_theme_colour_14="#EFEFEF"   # white
  tmux_conf_theme_colour_15="#EFEFEF"   # white
  tmux_conf_theme_colour_16="#830000"   # red
  tmux_conf_theme_colour_17="#1B1B1B"   # almost black
'';

# tmux cannot handle colors in the F ranges, e.g. #FNFNFN.
# They cause misalignment issues in the status bar for some unknown reason
# So using #EFEFEF for "white"
theme-status = ''
  # Message style.
  set -g message-style "fg=#143474,bg=#EFEFEF"
  tmux_conf_theme_message_fg="#143474"
  tmux_conf_theme_message_bg="#EFEFEF"
  set -g message-command-style "fg=#143474,bg=#EFEFEF"
  tmux_conf_theme_message_command_fg="#143474"
  tmux_conf_theme_message_command_bg="#EFEFEF"

  # Pane style.
  set -g pane-border-style "fg=#EFEFEF"
  tmux_conf_theme_pane_border_style_fg="#EFEFEF"
  set -g pane-active-border-style "fg=#EFEFEF"
  tmux_conf_theme_pane_active_border_style_fg="#EFEFEF"

  # Status style.
  set -g status-style "fg=#738E5C,bg=#EFEFEF"
  tmux_conf_theme_status_fg="#738E5C"
  tmux_conf_theme_status_bg="#EFEFEF"
  set -g status-left "#[fg=#EFEFEF,bg=#EFEFEF] #[fg=#8FBCBB,bg=#EFEFEF]  #[fg=#6B6272,bg=#EFEFEF] #S #[fg=#738E5C,bg=#EFEFEF]#[fg=#191C24,bg=#738E5C,bold]#{session_attached}#[fg=#738E5C,bg=#EFEFEF] "
  tmux_conf_theme_status_left="#[fg=#EFEFEF,bg=#EFEFEF] #[fg=#8FBCBB,bg=#EFEFEF]  #[fg=#6B6272,bg=#EFEFEF] #S #[fg=#738E5C,bg=#EFEFEF]#[fg=#191C24,bg=#738E5C,bold]#{session_attached}#[fg=#738E5C,bg=#EFEFEF] "
  set -g status-left-length 100
  tmux_conf_theme_status_left_length="100"
  set -g status-position top
  tmux_conf_theme_status_position="top"
  set -g status-justify left
  tmux_conf_theme_status_justify="left"

  set -g status-right-style "fg=#443C2B,bg=#EFEFEF"
  tmux_conf_theme_status_right_fg="#443C2B"
  tmux_conf_theme_status_right_bg="#EFEFEF"
  set -g status-right " #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#EFEFEF,bg=#738E5C,bold] #{username} #[bg=#d70000]#{root}#[fg=#EFEFEF,bg=#5F8C8B,bold] #{hostname} "
  tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#EFEFEF,bg=#738E5C,bold] #{username} #[bg=#d70000]#{root}#[fg=#EFEFEF,bg=#5F8C8B,bold] #{hostname} "

  # Window style.
  set -g window-status-style "bg=#738E5C"
  tmux_conf_theme_window_bg="#EFEFEF"
  set -g window-status-current-format "#[fg=#738E5C,bg=#EFEFEF]#[fg=#EFEFEF,bg=#738E5C,bold]#I:#W#[fg=#738E5C,bg=#EFEFEF]"
  tmux_conf_theme_window_status_current_format="#[fg=#738E5C,bg=#EFEFEF]#[fg=#EFEFEF,bg=#738E5C,bold]#I:#W#[fg=#738E5C,bg=#EFEFEF]"
  set -g window-status-current-style "bg=#EFEFEF"
  tmux_conf_theme_window_status_current_bg="#EFEFEF"
'';
in

{
  home.file.".system-theme" = lib.mkForce {
    text = "light-mode";
  };

  imports = [
    ( import ./tmux.nix (args // {
      forceConfig = true;
      theme-colors = theme-colors;
      theme-status = theme-status;
      userParams = userParams;
    }))
  ];

  # For X
  home.file.".Xresources".text = xwayland_settings;
  # For sway
  home.file.".Xdefaults".text = xwayland_settings;

  programs.zsh.plugins = [
    {
      name = "powerlevel10k-config";
      src = pkgs.writeTextFile {
        name = "p10k.zsh";
        destination = "/p10k.zsh";
        text = ((builtins.readFile ./zsh-p10k-config/p10k.zsh) + ''
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

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = gruvbox;
        config = lib.mkForce ''
          lua << EOF
          vim.o.background = "light"
          vim.g.gruvbox_contrast_light = "hard"
          -- vim.g.solarized_termcolors=256   -- only needed if terminal is not solarized
          vim.cmd [[colorscheme gruvbox]]
          EOF
        '';
      }
    ];
  };

  colorScheme = inputs.nix-colors.colorSchemes.atelier-forest-light;

  programs.kitty.extraConfig = lib.mkForce ''
    background            #efefef
    foreground            #414141
    cursor                #5e76c7
    selection_background  #6f6a4e
    color0                #414141
    color1                #b23670
    color2                #66781d
    color3                #cc6e33
    color4                #3b5ea7
    color5                #a353b2
    color6                #66781d
    color7                #efefef
    color8                #3e3e3e
    color9                #da3365
    color10               #829428
    color11               #cc6e33
    color12               #3b5ea7
    color13               #a353b2
    color14               #829428
    color15               #f1f1f1
    selection_foreground  #efefef
  '';

  programs.alacritty.settings = lib.mkForce {
    bell.color = "#000000";
    colors = {
      primary = {
        background            = "#efefef";
        foreground            = "#414141";
        cursor                = "#5e76c7";
        selection_background  = "#6f6a4e";
        color0                = "#414141";
        color1                = "#b23670";
        color2                = "#66781d";
        color3                = "#cc6e33";
        color4                = "#3b5ea7";
        color5                = "#a353b2";
        color6                = "#66781d";
        color7                = "#efefef";
        color8                = "#3e3e3e";
        color9                = "#da3365";
        color10               = "#829428";
        color11               = "#cc6e33";
        color12               = "#3b5ea7";
        color13               = "#a353b2";
        color14               = "#829428";
        color15               = "#f1f1f1";
        selection_foreground  = "#efefef";
      };
    };
  };

  programs.foot.settings = lib.mkForce {
    colors = {
      flash                 = "000000";
      background            = "efefef";
      foreground            = "414141";
      selection-background  = "6f6a4e";
      regular0              = "414141";
      regular1              = "b23670";
      regular2              = "66781d";
      regular3              = "cc6e33";
      regular4              = "3b5ea7";
      regular5              = "a353b2";
      regular6              = "66781d";
      regular7              = "efefef";
      bright0               = "3e3e3e";
      bright1               = "da3365";
      bright2               = "829428";
      bright3               = "cc6e33";
      bright4               = "3b5ea7";
      bright5               = "a353b2";
      bright6               = "829428";
      bright7               = "f1f1f1";
      selection-foreground  = "efefef";
    };
  };

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

  gtk = lib.mkForce {
    enable = true;

    # Used by Zenity and Firefox menus and tabs
    # GDK_DPI_SCALE is used in conjunction with this
    font = {
      name = "DejaVu Sans";
      size = 10;
    };

    theme.name = "Arc-Light";
    theme.package = pkgs.arc-theme;
    # theme.name = "SolArc-Dark";
    # theme.package = pkgs.solarc-gtk-theme;
    # theme.name = "Materia";
    # theme.package = pkgs.materia-theme;
    iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
    iconTheme.name = "Adwaita";

    gtk2.extraConfig =
      if hostParams.defaultSession == "none+i3" then ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=48
        gtk-application-prefer-dark-theme=0
      '' else ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=24
        gtk-application-prefer-dark-theme=0
      '';
    gtk3.extraConfig =
      if hostParams.defaultSession == "none+i3" then {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 48;
        "gtk-application-prefer-dark-theme" = 0;
      } else {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 24;
        "gtk-application-prefer-dark-theme" = 0;
      };
    gtk4.extraConfig =
      if hostParams.defaultSession == "none+i3" then {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 48;
      } else {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 24;
      };
  };

  dconf = lib.mkForce {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        "cursor-size" = if hostParams.defaultSession == "none+i3" then 48 else 24;
        "color-scheme" = "prefer-light";
      };
    };
  };

  qt = lib.mkForce {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name = "adwaita-light";
      package = pkgs.adwaita-qt;
    };
  };

  ## mkAfter makes sure this is at the end of the file,
  ## overrirding the theme at the top
  xdg.configFile."btop/btop.conf".text = lib.mkAfter ''
    #* Name of a btop++/bpytop/bashtop formatted ".theme" file, "Default" and "TTY" for builtin themes.
    #* Themes should be placed in "../share/btop/themes" relative to binary or "$HOME/.config/btop/themes"
    color_theme = "paper"
  '';

  # @TODO: move to a home.activation script?
  xdg.configFile.kcalcrc.text = lib.mkForce ''
    # [Colors]
    # BackColor=35,38,41
    # ConstantsButtonsColor=35,38,41
    # ConstantsFontsColor=252,252,252
    # ForeColor=255,255,255
    # FunctionButtonsColor=35,38,41
    # FunctionFontsColor=252,252,252
    # HexButtonsColor=35,38,41
    # HexFontsColor=252,252,252
    # MemoryButtonsColor=35,38,41
    # MemoryFontsColor=252,252,252
    # NumberButtonsColor=35,38,41
    # NumberFontsColor=252,252,252
    # OperationButtonsColor=35,38,41
    # OperationFontsColor=252,252,252
    # StatButtonsColor=35,38,41
    # StatFontsColor=252,252,252

    [General]
    CalculatorMode=science
    ShowHistory=true
  '';

  wayland.windowManager.sway.config.colors = lib.mkForce {
    focused = {
      background = "#bdd5fc";
      border = "#bdd5fc";
      childBorder = "#bdd5fc";
      indicator = "#2e9ef4";
      text = "#000000";
    };
    unfocused = {
      background = "#ababab";
      border = "#ababab";
      childBorder = "#ababab";
      indicator = "#2e9ef4";
      text = "#444444";
    };
  };

  wayland.windowManager.hyprland.settings.group = lib.mkForce {
    insert_after_current = false;
    "col.border_active" = "rgba(c4c4f1ff)";
    "col.border_inactive" = "rgba(afafafff)";
    groupbar = {
      font_family = "DejaVu Sans";
      font_size = 20;
      height = 22;
      text_color = "rgba(000000ff)";
      "col.active" = "rgba(c4d4f1ff)";
      "col.inactive" = "rgba(afafafff)";
    };
  };

  programs.waybar.style = lib.mkForce ''
    ${builtins.readFile ./waybar/waybar-angular-light.css}
  '';

  programs.waybar.settings.mainBar."custom/toggletheme".format = lib.mkForce "☼";

  xdg.configFile."swaync/style.css".source = lib.mkForce swaynotificationcenter/style-light.css;

  # @TODO: split this up so only the color bits are not shared
  xdg.configFile."rofi/launcher.rasi".source = lib.mkForce ./rofi/launcher-light.rasi;

  services.random-background.imageDirectory =
    lib.mkForce "%h/backgrounds/light";
}
