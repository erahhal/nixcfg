{ pkgs, lib, inputs, hostParams, ... }:
let
xwayland_settings = ''
  Xcursor.size: ${if hostParams.defaultSession == "none+i3" then "48" else "24"}
  Xcursor.theme: Adwaita
  Xft.dpi: 100
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

  localConf = builtins.readFile ./tmux/tmux.conf.local;
in

{
  home.file.".system-theme" = lib.mkForce {
    text = "light-mode";
  };

  # @TODO: this shouldn't be duplicated
  # @TODO: home.file."filename".text = "blah"; CAN be duplicated. use lib.mkBefore / lib.mkAfter to order
  home.file.".tmux.conf.local" = lib.mkForce { text = builtins.replaceStrings ["[THEME_COLORS_TOKEN]"] [theme-colors] localConf + ''
    # -- Ellis' Settings -----------------------------------------------------------

    ### TODO:
    ### Get rid of manual modification in tmux.conf of
    ### spacer_activity to a space and spacer_current to an empty string

    # Plugins
    run-shell ${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux
    run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
    run-shell ${pkgs.tmuxPlugins.open}/share/tmux-plugins/open/open.tmux
    set -g @resurrect-strategy-vim 'session'
    set -g @resurrect-strategy-nvim 'session'
    # set -g @resurrect-capture-pane-contents 'on'
    # set -g @resurrect-save-bash-history 'on'
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '5' # minutes
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux

    # set-option -sa terminal-overrides ',xterm-kitty:RGB'
    set-option -sa terminal-features ',xterm-kitty:RGB'

    # set-option -g default-shell /bin/zsh

    set -g status-position top

    # For sharing clipboard with vim
    set -g focus-events on

    set -gu prefix2
    unbind C-a
    unbind C-b
    set -g prefix C-a
    bind C-a send-prefix

    # smart pane switching with awareness of vim splits
    bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-h) || tmux select-pane -L"
    bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-j) || tmux select-pane -D"
    bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-k) || tmux select-pane -U"
    bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-l) || tmux select-pane -R"
    bind -n 'C-\' run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys 'C-\\') || tmux select-pane -l"

    ${theme-status}
 '';
 };

  # For X
  home.file.".Xresources".text = xwayland_settings;
  # For sway
  home.file.".Xdefaults".text = xwayland_settings;

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
    color8                #3e3e3e
    color1                #b23670
    color9                #da3365
    color2                #66781d
    color10               #829428
    color3                #cc6e33
    color11               #cc6e33
    color4                #3b5ea7
    color12               #3b5ea7
    color5                #a353b2
    color13               #a353b2
    color6                #66781d
    color14               #829428
    color7                #efefef
    color15               #f1f1f1
    selection_foreground  #efefef
  '';

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
    platformTheme = "gnome";
    style = {
      name = "adwaita-light";
      package = pkgs.adwaita-qt;
    };
  };

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

  services.random-background.imageDirectory =
    lib.mkForce "%h/backgrounds/light";
}
