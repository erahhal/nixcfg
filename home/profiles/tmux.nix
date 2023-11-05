{ pkgs, ... }:
let
  # Files from https://github.com/gpakosz/.tmux
  conf = builtins.readFile ./tmux/tmux.conf;
  localConf = builtins.readFile ./tmux/tmux.conf.local;
in
{
  home.packages = with pkgs; [
    tmux
    tmuxPlugins.continuum
    tmuxPlugins.cpu
    tmuxPlugins.open
    tmuxPlugins.resurrect
    tmuxPlugins.sensible
  ];
  # xdg.configFile."tmux/tmux.conf".text = builtins.replaceStrings ["~/.tmux.conf.local"] ["~/.config/tmux/tmux.conf.local"] conf;
  home.file.".tmux.conf".text = conf;
  # xdg.configFile."tmux/tmux.conf.local".text = localConf + ''
  home.file.".tmux.conf.local".text = localConf + ''

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
   # set -g status-left "#[fg=#191C24,bg=#191C24] #[fg=#8FBCBB,bg=#191C24]   "
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
   # set -g window-status-style "fg=#434C5E,bg=#191C24"
   # tmux_conf_theme_window_fg="#434C5E"
   set -g window-status-style "bg=#191C24"
   tmux_conf_theme_window_bg="#191C24"
   set -g window-status-current-format "#[fg=#8FBCBB,bg=#191C24]#[fg=#191C24,bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
   tmux_conf_theme_window_status_current_format="#[fg=#8FBCBB,bg=#191C24]#[fg=#191C24,bg=#8FBCBB,bold]#I:#W#[fg=#8FBCBB,bg=#191c24]"
   set -g window-status-current-style "bg=#191C24"
   tmux_conf_theme_window_status_current_bg="#191C24"
   # set -g window-status-format "#I:#W"
   # tmux_conf_theme_window_status_format="#I:#W"
 '';
}
