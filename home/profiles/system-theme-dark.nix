args@{ osConfig, inputs, pkgs, lib, userParams, ... }:
let
xwayland_settings = ''
  ## Used in QT and other Xwayland apps
  Xcursor.size: ${if osConfig.hostParams.desktop.defaultSession == "none+i3" then "32" else "16"}
  # Xcursor.theme: Adwaita
  Xcursor.theme: Bibata-Modern-Classic
  xterm*background: black
  xterm*faceName: Monospace
  xterm*faceSize: 12
  xterm*foreground: lightgray
'' + (if osConfig.hostParams.desktop.disableXwaylandScaling then ''
  Xft.dpi: ${toString osConfig.hostParams.desktop.dpi}
'' else "");

# tmux-background = "#080808";
# tmux-background = "${tmux-background}";
tmux-background = "#000000";

theme-colors = ''
  # default theme
  tmux_conf_theme_colour_1="${tmux-background}"
  tmux_conf_theme_colour_2="#303030"    # gray
  tmux_conf_theme_colour_3="#8a8a8a"    # light gray
  tmux_conf_theme_colour_4="#00afff"    # light blue
  tmux_conf_theme_colour_5="#ffff00"    # yellow
  tmux_conf_theme_colour_6="${tmux-background}"
  tmux_conf_theme_colour_6="#000000"    # black
  tmux_conf_theme_colour_7="#e4e4e4"    # white
  tmux_conf_theme_colour_8="${tmux-background}"
  tmux_conf_theme_colour_8="#000000"    # black
  tmux_conf_theme_colour_9="#ffff00"    # yellow
  tmux_conf_theme_colour_10="#ff00af"   # pink
  tmux_conf_theme_colour_11="#5fff00"   # green
  tmux_conf_theme_colour_12="#8a8a8a"   # light gray
  tmux_conf_theme_colour_13="#e4e4e4"   # white
  tmux_conf_theme_colour_14="${tmux-background}"
  tmux_conf_theme_colour_15="${tmux-background}"
  tmux_conf_theme_colour_16="#d70000"   # red
  tmux_conf_theme_colour_17="#e4e4e4"   # white
'';

theme-status = ''
  # Message style.
  set -g message-style "fg=#EBCB8B,bg=${tmux-background}"
  tmux_conf_theme_message_fg="#EBCB8B"
  tmux_conf_theme_message_bg="${tmux-background}"
  set -g message-command-style "fg=#EBCB8B,bg=${tmux-background}"
  tmux_conf_theme_message_command_fg="#EBCB8B"
  tmux_conf_theme_message_command_bg="${tmux-background}"

  # Pane style.
  set -g pane-border-style "fg=${tmux-background}"
  tmux_conf_theme_pane_border_style_fg="${tmux-background}"
  set -g pane-active-border-style "fg=${tmux-background}"
  tmux_conf_theme_pane_active_border_style_fg="${tmux-background}"

  # Status style.
  set -g status-style "fg=#BBC3D4,bg=${tmux-background}"
  tmux_conf_theme_status_fg="#BBC3D4"
  tmux_conf_theme_status_bg="${tmux-background}"
  set -g status-left "#[fg=${tmux-background},bg=${tmux-background}] #[fg=#8FBCBB,bg=${tmux-background}]  #[fg=#6B6272,bg=${tmux-background}] #S #[fg=#A3BE8C,bg=${tmux-background}]#[fg=${tmux-background},bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=${tmux-background}] "
  tmux_conf_theme_status_left="#[fg=${tmux-background},bg=${tmux-background}] #[fg=#8FBCBB,bg=${tmux-background}]  #[fg=#6B6272,bg=${tmux-background}] #S #[fg=#A3BE8C,bg=${tmux-background}]#[fg=${tmux-background},bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=${tmux-background}] "
  set -g status-left-length 100
  tmux_conf_theme_status_left_length="100"
  set -g status-position top
  tmux_conf_theme_status_position="top"
  set -g status-justify left
  tmux_conf_theme_status_justify="left"

  set -g status-right-style "fg=#BBC3D4,bg=${tmux-background}"
  tmux_conf_theme_status_right_fg="#BBC3D4"
  tmux_conf_theme_status_right_bg="${tmux-background}"
  set -g status-right " #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=${tmux-background},bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=${tmux-background},bg=#8FBCBB,bold] #{hostname} "
  tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=${tmux-background},bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=${tmux-background},bg=#8FBCBB,bold] #{hostname} "

  # Window style.
  set -g window-status-style "bg=${tmux-background}"
  tmux_conf_theme_window_bg="${tmux-background}"
  set -g window-status-current-format "#[fg=#8FBCBB,bg=${tmux-background}]#[fg=${tmux-background},bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
  tmux_conf_theme_window_status_current_format="#[fg=#8FBCBB,bg=${tmux-background}]#[fg=${tmux-background},bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
  set -g window-status-current-style "bg=${tmux-background}"
  tmux_conf_theme_window_status_current_bg="${tmux-background}"
'';

in
{
  home.file.".system-theme" = {
    text = "dark-mode";
  };

  home.packages = with pkgs; [
    libadwaita
  ];

  imports = [
    ( import ./tmux.nix (args // {
      forceConfig = false;
      theme-colors = theme-colors;
      theme-status = theme-status;
      userParams = userParams;
    }))
  ];

  ## Example custom color scheme
  # colorScheme = {
  #   slug = "pasque";
  #   name = "Pasque";
  #   author = "Gabriel Fontes (https://github.com/Misterio77)";
  #   colors = {
  #     base00 = "#271C3A";
  #     base01 = "#100323";
  #     base02 = "#3E2D5C";
  #     base03 = "#5D5766";
  #     base04 = "#BEBCBF";
  #     base05 = "#DEDCDF";
  #     base06 = "#EDEAEF";
  #     base07 = "#BBAADD";
  #     base08 = "#A92258";
  #     base09 = "#918889";
  #     base0A = "#804ead";
  #     base0B = "#C6914B";
  #     base0C = "#7263AA";
  #     base0D = "#8E7DC6";
  #     base0E = "#953B9D";
  #     base0F = "#59325C";
  #   };
  # };

  ## Example from yaml
  # colorScheme = nix-colors.lib.schemeFromYAML "cool-scheme" (builtins.readFile ./cool-scheme.yaml);

  colorScheme = inputs.nix-colors.colorSchemes.dracula;

  # For X
  home.file.".Xresources".text = xwayland_settings;
  # For sway
  home.file.".Xdefaults".text = xwayland_settings;

  # programs = {
  #   kitty = {
  #     enable = true;
  #     settings = {
  #       foreground =            "#${config.colorScheme.colors.base05}";
  #       background =            "#${config.colorScheme.colors.base00}";
  #       selection_foreground =  "#${config.colorScheme.colors.base05}";
  #       selection_background =  "#${config.colorScheme.colors.base02}";
  #       cursor =                "#${config.colorScheme.colors.base05}";
  #       cursor_text_color =     "#${config.colorScheme.colors.base00}";
  #       url_color =             "#${config.colorScheme.colors.base09}";
  #       active_border_color =   "#${config.colorScheme.colors.base00}";
  #       # inactive_border_color = "";
  #       # bell_border_color     = "";
  #       # visual_bell_color     = "";
  #     };
  #   };
  # };

  programs.kitty.extraConfig = ''
    background            #000000
    foreground            #e9e9e9
    cursor                #e9e9e9
    selection_background  #424242
    color0                #000000
    color8                #777777
    color1                #d44d53
    color9                #d44d53
    color2                #b9c949
    color10               #b9c949
    color3                #e6c446
    color11               #e6c446
    color4                #79a6da
    color12               #79a6da
    color5                #c396d7
    color13               #c396d7
    color6                #70c0b1
    color14               #70c0b1
    color7                #fffefe
    color15               #fffefe
    selection_foreground  #000000
  '';

  programs.alacritty.settings = {
    bell.color = "#ffffff";
    colors = {
      primary = {
        background            = "#000000";
        foreground            = "#e9e9e9";
        cursor                = "#e9e9e9";
        selection_background  = "#424242";
        color0                = "#000000";
        color8                = "#777777";
        color1                = "#d44d53";
        color9                = "#d44d53";
        color2                = "#b9c949";
        color10               = "#b9c949";
        color3                = "#e6c446";
        color11               = "#e6c446";
        color4                = "#79a6da";
        color12               = "#79a6da";
        color5                = "#c396d7";
        color13               = "#c396d7";
        color6                = "#70c0b1";
        color14               = "#70c0b1";
        color7                = "#fffefe";
        color15               = "#fffefe";
        selection_foreground  = "#000000";
      };
    };
  };

  programs.foot.settings = {
    colors = {
      flash                 = "ffffff";
      background            = "000000";
      foreground            = "e9e9e9";
      selection-background  = "424242";
      regular0              = "000000";
      bright0               = "777777";
      regular1              = "d44d53";
      bright1               = "d44d53";
      regular2              = "b9c949";
      bright2               = "b9c949";
      regular3              = "e6c446";
      bright3               = "e6c446";
      regular4              = "79a6da";
      bright4               = "79a6da";
      regular5              = "c396d7";
      bright5               = "c396d7";
      regular6              = "70c0b1";
      bright6               = "70c0b1";
      regular7              = "fffefe";
      bright7               = "fffefe";
      selection-foreground  = "000000";
    };
  };

  programs.zsh.plugins = [
    {
      name = "powerlevel10k-config";
      src = ./zsh-p10k-config;
      file = "p10k.zsh";
    }
  ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = gruvbox;
        config = ''
          lua << EOF
          -- vim.g.solarized_termcolors=256   -- only needed if terminal is not solarized
          vim.cmd.colorscheme('gruvbox')
          vim.api.nvim_set_hl(0, "Normal", { bg = "#000000"})
          vim.api.nvim_set_hl(0, "CursorLine", { bg = "#242424"})
          EOF
        '';
      }
    ];
  };

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  gtk = {
    enable = true;

    # Used by Zenity and Firefox menus and tabs
    # GDK_DPI_SCALE is used in conjunction with this
    font = {
      name = "DejaVu Sans";
      size = 10;
    };

    ##----------------------------------------------
    ## Works well
    ##----------------------------------------------

    ## Good looking, some buttons are same color as background
    theme.name = "Tokyonight-Dark";
    theme.package = pkgs.tokyonight-gtk-theme;

    ## OK, kind of old-school
    # theme.name = "Zukitwo-dark";
    ## More modern, but some black on dark fonts
    # theme.name = "Zukitre-dark";
    # theme.package = pkgs.zuki-themes;

    ## Decent looking
    # theme.name = "Orchis-Dark";
    ## Nice and tight
    # theme.name = "Orchis-Dark-Compact";
    # theme.name = "Orchis-Teal-Dark";
    ## Even better
    # theme.name = "Orchis-Teal-Dark-Compact";
    # theme.name = "Orchis-<color>";
    # theme.name = "Orchis-<color>-Dark";
    # theme.name = "Orchis-<color>-Compact";
    # theme.name = "Orchis-<color>-Dark-Compact";
    # theme.package = pkgs.orchis-theme;

    ## Dark bluish with green highlights
    # theme.name = "Matrix-Dark";
    # theme.package = pkgs.matrix-gtk-theme;

    ## Decent, dark violet with light blue highlights
    # theme.name = "Nightfox-Dark";
    # theme.package = pkgs.nightfox-gtk-theme;

    ## Ok, a bit too tight with padding
    # theme.name = "Layan-Dark";
    # theme.name = "Layan-Dark-Solid";
    # theme.package = pkgs.layan-gtk-theme;

    ## Nice dark brown theme with dark blue highlights
    # theme.name = "Gruvbox-Dark";
    # theme.package = pkgs.gruvbox-gtk-theme;

    # theme.name = "Gruvbox-Material-Dark";
    # theme.package = pkgs.gruvbox-material-gtk-theme;

    ## Dark with white highlights
    # theme.name = "Graphite-Dark";
    # theme.package = pkgs.graphite-gtk-theme;

    ## Dark with white highlights
    # theme.name = "Fluent-Dark";
    # theme.package = pkgs.fluent-gtk-theme;

    ##----------------------------------------------
    ## Problematic
    ##----------------------------------------------

    ## Dark mode, but gtk4 apps are light
    # theme.name = "Plano";
    # theme.name = "Plano-dark-titlebar";
    # theme.package = pkgs.plano-theme;

    ## "light" theme with darkish chrome
    # theme.name = "rose-pine";
    ## "dark" theme with light-ish chrome, white title bars
    # theme.name = "rose-pine-dawn";
    ## "light" theme with darkish chrome
    # theme.name = "rose-pine-moon";
    # theme.package = pkgs.rose-pine-gtk-theme;

    ## Dark mode, but bright white title bars
    # theme.name = "Materia-dark";
    # theme.package = pkgs.materia-theme;

    ##----------------------------------------------
    ## Broken/Unimplemented on GTK4
    ##----------------------------------------------

    # theme.name = "Adwaita-dark";
    # theme.package = pkgs.gnome-themes-extra;
    # theme.name = "Arc-Dark";
    # theme.package = pkgs.arc-theme;
    # theme.name = "SolArc-Dark";
    # theme.package = pkgs.solarc-gtk-theme;
    # theme.name = "Pop-dark";
    # theme.package = pkgs.pop-gtk-theme;
    # theme.name = "Plata-noir";
    # theme.package = pkgs.plata-theme;
    # theme.name = "Paper";
    # theme.package = pkgs.paper-gtk-theme;
    # theme.name = "palenight";
    # theme.package = pkgs.palenight-theme;
    # theme.name = "oceanic";
    # theme.package = pkgs.oceanic-theme;
    # theme.name = "Numix";
    # theme.package = pkgs.numix-gtk-theme;
    # theme.name = "Omni";
    # theme.package = pkgs.omni-gtk-theme;
    # theme.name = "Adapta";
    # theme.package = pkgs.adapta-gtk-theme;

    iconTheme.package = pkgs.adwaita-icon-theme;
    iconTheme.name = "Adwaita";
    # iconTheme.package = pkgs.pop-icon-theme;
    # iconTheme.name = "Pop";
    # iconTheme.name = "Papirus-Dark";
    # iconTheme.package = pkgs.papirus-icon-theme;

    gtk2.extraConfig =
      if osConfig.hostParams.desktop.defaultSession == "none+i3" then ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=48
        gtk-application-prefer-dark-theme=1
      '' else ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=24
        gtk-application-prefer-dark-theme=1
      '';
    gtk3.extraConfig =
      if osConfig.hostParams.desktop.defaultSession == "none+i3" then {
        gtk-cursor-theme-name = "Bibata-Modern-Classic";
        gtk-cursor-theme-size = 48;
        gtk-application-prefer-dark-theme = 1;
      } else {
        gtk-cursor-theme-name = "Bibata-Modern-Classic";
        gtk-cursor-theme-size = 24;
        gtk-application-prefer-dark-theme = 1;
      };
    gtk4.extraConfig =
      if osConfig.hostParams.desktop.defaultSession == "none+i3" then {
        gtk-cursor-theme-name = "Bibata-Modern-Classic";
        gtk-cursor-theme-size = 48;
        gtk-application-prefer-dark-theme = 1;
      } else {
        gtk-cursor-theme-name = "Bibata-Modern-Classic";
        gtk-cursor-theme-size = 24;
        gtk-application-prefer-dark-theme = 1;
      };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        # "cursor-size" = if osConfig.hostParams.desktop.defaultSession == "none+i3" then 48 else 24;
        "color-scheme" = "prefer-dark";
        # Disable trackpad middle click paste
        "gtk-enable-primary-paste" = false;
      };
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  ## Use Kvantum theme
  # qt = {
  #   enable = true;
  #   platformTheme.name = "qtct";
  #   style.name = "kvantum";
  # };
  # home.sessionVariables = {
  #   QT_QPA_PLATFORM_THEME = "qt5ct";
  #   QT_STYLE_OVERRIDE = "kvantum";
  # };
  # xdg.configFile = {
  #   "Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";
  #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=ArcDark";
  # };

  # xdg.configFile = {
  #   "Kvantum/AdaptaNokto".source = "${pkgs.adapta-kde-theme}/share/Kvantum/AdaptaNokto";
  #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=AdaptaNokto";
  # };
  # xdg.configFile = {
  #   "Kvantum/Graphite".source = "${pkgs.graphite-kde-theme}/share/Kvantum/Graphite";
  #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=GraphiteDark";
  # };
  # xdg.configFile = {
  #   "Kvantum/GraphiteNord".source = "${pkgs.graphite-kde-theme}/share/Kvantum/GraphiteNord";
  #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=GraphiteNordDark";
  # };
  # xdg.configFile = {
  #   "Kvantum/MateriaDark".source = "${pkgs.materia-kde-theme}/share/Kvantum/MateriaDark";
  #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=MateriaDark";
  # };

  # @TODO: move to a home.activation script?
  xdg.configFile.kcalcrc.text = ''
    [Colors]
    BackColor=35,38,41
    ConstantsButtonsColor=35,38,41
    ConstantsFontsColor=252,252,252
    ForeColor=255,255,255
    FunctionButtonsColor=35,38,41
    FunctionFontsColor=252,252,252
    HexButtonsColor=35,38,41
    HexFontsColor=252,252,252
    MemoryButtonsColor=35,38,41
    MemoryFontsColor=252,252,252
    NumberButtonsColor=35,38,41
    NumberFontsColor=252,252,252
    OperationButtonsColor=35,38,41
    OperationFontsColor=252,252,252
    StatButtonsColor=35,38,41
    StatFontsColor=252,252,252

    [General]
    CalculatorMode=science
    ShowHistory=true
  '';


  wayland.windowManager.sway.config.colors = {
    focused = {
      background = "#285577";
      border = "#4a7697";
      childBorder = "#4a7697";
      indicator = "#ee7e04";
      text = "#ffffff";
    };
    unfocused = {
      background = "#2b2b2b";
      border = "#2b2b2b";
      childBorder = "#2b2b2b";
      indicator = "#2e9ef4";
      text = "#848484";
    };
  };

  wayland.windowManager.hyprland.settings.group = {
    insert_after_current = false;
    "col.border_active" = "rgba(285577ff)";
    "col.border_inactive" = "rgba(2b2b2bff)";
    groupbar = {
      gradients = true;
      font_size = 14;
      height = 24;
      indicator_height = 0;
      text_color = "rgba(ffffffff)";
      "col.active" = "rgba(285577ff)";
      "col.inactive" = "rgba(2b2b2bff)";
      gaps_in = 0;
      gaps_out = 0;
    };
  };

  programs.waybar.style = ''
    ${builtins.readFile ./waybar/waybar-angular.css}
  '';

  xdg.configFile."nwg-drawer/drawer.css".source = ./nwg-drawer/drawer.css;

  programs.waybar.settings.mainBar."custom/toggletheme".format = "☽";

  # @TODO: split this up so only the color bits are not shared
  xdg.configFile."rofi/launcher.rasi".source = ./rofi/launcher.rasi;

  services.random-background.imageDirectory =
    lib.mkForce "%h/backgrounds/dark";

}
