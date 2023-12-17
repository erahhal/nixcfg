args@{ pkgs, lib, inputs, userParams, ... }:
let
theme-colors = ''
  # default theme
  tmux_conf_theme_colour_1="#FFFFFF"    # white
  tmux_conf_theme_colour_2="#CFCFCF"    # gray
  tmux_conf_theme_colour_3="#757575"    # dark gray
  tmux_conf_theme_colour_4="#008CCC"    # light blue
  tmux_conf_theme_colour_5="#999900"    # yellow
  tmux_conf_theme_colour_6="#080808"    # dark gray
  tmux_conf_theme_colour_7="#e4e4e4"    # white
  tmux_conf_theme_colour_8="#FFFFFF"    # white
  tmux_conf_theme_colour_9="#999900"    # yellow
  tmux_conf_theme_colour_10="#AA007A"   # pink
  tmux_conf_theme_colour_11="#288800"   # green
  tmux_conf_theme_colour_12="#757575"   # dark gray
  tmux_conf_theme_colour_13="#1B1B1B"   # almost black
  tmux_conf_theme_colour_14="#FFFFFF"   # white
  tmux_conf_theme_colour_15="#FFFFFF"   # white
  tmux_conf_theme_colour_16="#830000"   # red
  tmux_conf_theme_colour_17="#1B1B1B"   # almost black
'';
theme-status = ''
  # Message style.
  set -g message-style "fg=#143474,bg=#FFFFFF"
  tmux_conf_theme_message_fg="#143474"
  tmux_conf_theme_message_bg="#FFFFFF"
  set -g message-command-style "fg=#143474,bg=#FFFFFF"
  tmux_conf_theme_message_command_fg="#143474"
  tmux_conf_theme_message_command_bg="#FFFFFF"

  # Pane style.
  set -g pane-border-style "fg=#FFFFFF"
  tmux_conf_theme_pane_border_style_fg="#FFFFFF"
  set -g pane-active-border-style "fg=#FFFFFF"
  tmux_conf_theme_pane_active_border_style_fg="#FFFFFF"

  # Status style.
  set -g status-style "fg=#A3BE8C,bg=#FFFFFF"
  tmux_conf_theme_status_fg="#A3BE8C"
  tmux_conf_theme_status_bg="#FFFFFF"
  set -g status-left "#[fg=#FFFFFF,bg=#FFFFFF] #[fg=#8FBCBB,bg=#FFFFFF]  #[fg=#6B6272,bg=#FFFFFF] #S #[fg=#A3BE8C,bg=#FFFFFF]#[fg=#191C24,bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=#FFFFFF] "
  tmux_conf_theme_status_left="#[fg=#FFFFFF,bg=#FFFFFF] #[fg=#8FBCBB,bg=#FFFFFF]  #[fg=#6B6272,bg=#FFFFFF] #S #[fg=#A3BE8C,bg=#FFFFFF]#[fg=#191C24,bg=#A3BE8C,bold]#{session_attached}#[fg=#A3BE8C,bg=#FFFFFF] "
  set -g status-left-length 100
  tmux_conf_theme_status_left_length="100"
  set -g status-position top
  tmux_conf_theme_status_position="top"
  set -g status-justify left
  tmux_conf_theme_status_justify="left"

  set -g status-right-style "fg=#443C2B,bg=#FFFFFF"
  tmux_conf_theme_status_right_fg="#443C2B"
  tmux_conf_theme_status_right_bg="#FFFFFF"
  set -g status-right " #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#FFFFFF,bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=#FFFFFF,bg=#8FBCBB,bold] #{hostname} "
  tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#FFFFFF,bg=#A3BE8C,bold] #{username} #[bg=#d70000]#{root}#[fg=#FFFFFF,bg=#8FBCBB,bold] #{hostname} "

  # Window style.
  set -g window-status-style "bg=#A3BE8C"
  tmux_conf_theme_window_bg="#FFFFFF"
  set -g window-status-current-format "#[fg=#A3BE8C,bg=#FFFFFF]#[fg=#FFFFFF,bg=#A3BE8C,bold]#I:#W#[fg=#A3BE8C,bg=#FFFFFF]"
  tmux_conf_theme_window_status_current_format="#[fg=#A3BE8C,bg=#FFFFFF]#[fg=#FFFFFF,bg=#A3BE8C,bold]#I:#W#[fg=#A3BE8C,bg=#FFFFFF]"
  set -g window-status-current-style "bg=#FFFFFF"
  tmux_conf_theme_window_status_current_bg="#FFFFFF"
'';
in
{
  home-manager.users.${userParams.username} = {
    imports = [
      ( import ../home/profiles/tmux.nix (args // { theme-colors = theme-colors; theme-status = theme-status; }))
    ];

    programs.zathura.extraConfig = builtins.readFile "${inputs.base16-zathura}/build_schemes/colors/base16-nord.config";

    programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        # {
        #   plugin = nvim-base16;
        #   config = ''
        #     lua << EOF
        #
        #     -- All builtin colorschemes can be accessed with |:colorscheme|.
        #     vim.cmd('colorscheme base16-solarized-light')
        #
        #     -- Alternatively, you can provide a table specifying your colors to the setup function.
        #
        #     -- require('base16-colorscheme').setup({
        #     --   base00 = '#16161D', base01 = '#2c313c', base02 = '#3e4451', base03 = '#6c7891',
        #     --   base04 = '#565c64', base05 = '#abb2bf', base06 = '#9a9bb3', base07 = '#c5c8e6',
        #     --   base08 = '#e06c75', base09 = '#d19a66', base0A = '#e5c07b', base0B = '#98c379',
        #     --   base0C = '#56b6c2', base0D = '#0184bc', base0E = '#c678dd', base0F = '#a06949',
        #     -- })
        #
        #     EOF
        #   '';
        # }

        {
          plugin = neovim-ayu;
          config = ''
            lua << EOF
            vim.o.background = "light"
            require('ayu').setup({
              mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
              overrides = {}, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
            })
            -- vim.cmd [[colorscheme ayu}]]
            EOF
          '';
        }

        {
          plugin = lualine-nvim;
          config = ''
          lua << EOF
          require('lualine').setup {
            options = { theme = 'ayu' }
          }
          EOF
          '';
        }

        {
          plugin = lualine-lsp-progress;
          config = ''
            lua << EOF
            require('lualine').setup {
              options = { theme = 'ayu' },
              sections = {
                lualine_c = {
                  'lsp_progress'
                }
              }
            }
            EOF
          '';
        }
      ];
    };

    programs.kitty.extraConfig = ''
      background            #ffffff
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
      color7                #ffffff
      color15               #f1f1f1
      selection_foreground #ffffff
    '';

    services.random-background.imageDirectory =
      lib.mkForce "%h/backgrounds/light";
  };
}
