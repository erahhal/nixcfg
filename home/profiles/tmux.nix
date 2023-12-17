{ pkgs, theme-colors, theme-status, ... }:
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
  home.file.".tmux.conf".text = conf;
  home.file.".tmux.conf.local".text = builtins.replaceStrings ["[THEME_COLORS_TOKEN]"] [theme-colors] localConf + ''
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
}
