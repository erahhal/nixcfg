args@{ pkgs, lib, inputs, ... }:
let
theme-colors = ''
  # default theme
  tmux_conf_theme_colour_1="#080808"    # dark gray
  tmux_conf_theme_colour_2="#303030"    # gray
  tmux_conf_theme_colour_3="#8a8a8a"    # light gray
  tmux_conf_theme_colour_4="#00afff"    # light blue
  tmux_conf_theme_colour_5="#ffff00"    # yellow
  tmux_conf_theme_colour_6="#080808"    # dark gray
  tmux_conf_theme_colour_7="#e4e4e4"    # white
  tmux_conf_theme_colour_8="#080808"    # dark gray
  tmux_conf_theme_colour_9="#ffff00"    # yellow
  tmux_conf_theme_colour_10="#ff00af"   # pink
  tmux_conf_theme_colour_11="#5fff00"   # green
  tmux_conf_theme_colour_12="#8a8a8a"   # light gray
  tmux_conf_theme_colour_13="#e4e4e4"   # white
  tmux_conf_theme_colour_14="#080808"   # dark gray
  tmux_conf_theme_colour_15="#080808"   # dark gray
  tmux_conf_theme_colour_16="#d70000"   # red
  tmux_conf_theme_colour_17="#e4e4e4"   # white
'';
theme-status = ''
  # Message style.
  set -g message-style "fg=#EBCB8B,bg=#191C24"
  tmux_conf_theme_message_fg="#EBCB8B"
  tmux_conf_theme_message_bg="#191C24"
  set -g message-command-style "fg=#EBCB8B,bg=#191C24"
  tmux_conf_theme_message_command_fg="#EBCB8B"
  tmux_conf_theme_message_command_bg="#191C24"

  # Pane style.
  set -g pane-border-style "fg=#191C24"
  tmux_conf_theme_pane_border_style_fg="#191C24"
  set -g pane-active-border-style "fg=#191C24"
  tmux_conf_theme_pane_active_border_style_fg="#191C24"

  # Status style.
  set -g status-style "fg=#BBC3D4,bg=#191C24"
  tmux_conf_theme_status_fg="#BBC3D4"
  tmux_conf_theme_status_bg="#191C24"
  set -g status-left "#[fg=#191C24,bg=#191C24] #[fg=#8FBCBB,bg=#191C24]  #[fg=#6B6272,bg=#191C24] #S #[fg=#A3BE8C,bg=#191C24]#[fg=#191C24,bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=#191C24] "
  tmux_conf_theme_status_left="#[fg=#191C24,bg=#191C24] #[fg=#8FBCBB,bg=#191C24]  #[fg=#6B6272,bg=#191C24] #S #[fg=#A3BE8C,bg=#191C24]#[fg=#191C24,bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=#191C24] "
  set -g status-left-length 100
  tmux_conf_theme_status_left_length="100"
  set -g status-position top
  tmux_conf_theme_status_position="top"
  set -g status-justify left
  tmux_conf_theme_status_justify="left"

  set -g status-right-style "fg=#BBC3D4,bg=#191C24"
  tmux_conf_theme_status_right_fg="#BBC3D4"
  tmux_conf_theme_status_right_bg="#191C24"
  set -g status-right " #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#191C24,bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=#191C24,bg=#8FBCBB,bold] #{hostname} "
  tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#191C24,bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=#191C24,bg=#8FBCBB,bold] #{hostname} "

  # Window style.
  set -g window-status-style "bg=#191C24"
  tmux_conf_theme_window_bg="#191C24"
  set -g window-status-current-format "#[fg=#8FBCBB,bg=#191C24]#[fg=#191C24,bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
  tmux_conf_theme_window_status_current_format="#[fg=#8FBCBB,bg=#191C24]#[fg=#191C24,bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
  set -g window-status-current-style "bg=#191C24"
  tmux_conf_theme_window_status_current_bg="#191C24"
'';
in
{
  home.file.".system-theme" = {
    text = "dark-mode";
  };

  imports = [
    ( import ./tmux.nix (args // { theme-colors = theme-colors; theme-status = theme-status; }))
  ];

  programs.zathura.extraConfig = builtins.readFile "${inputs.base16-zathura}/build_schemes/colors/base16-nord.config";

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = gruvbox;
        config = ''
          lua << EOF
          -- vim.g.solarized_termcolors=256   -- only needed if terminal is not solarized
          vim.cmd [[colorscheme gruvbox]]
          EOF
        '';
      }
    ];
  };

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
    selection_foreground #000000
  '';

  services.random-background.imageDirectory =
    lib.mkForce "%h/backgrounds/dark";

}
