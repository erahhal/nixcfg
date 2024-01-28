{ pkgs, lib, forceConfig, theme-colors, theme-status, userParams, ... }:
let
  tmux-conf = pkgs.callPackage ../../pkgs/tmux-conf {};
  tmuxConfBase = builtins.readFile "${tmux-conf}/.tmux.conf";
  tmuxConfLocal = builtins.readFile "${tmux-conf}/.tmux.conf.local";
  term = if userParams.tty == "kitty" then "xterm-kitty" else "xterm-256color";

  ## Tmux config is stitched together as follows:
  ## * tmux.conf from the gpakosz repo is bound to ~/.tmux.conf
  ## * tmux.conf.local is bound to ~/.tmux.conf.local and loaded by tmux.conf
  ## * tmux.conf.local is stitched together from tmux.conf.local from the gpakosz repo and personal config
  ##   * Order of config in tmux config matters
  ##   * Some theme changes are patched in tmux.conf.local
  ##   * them tmux.conf.local is stitched together with personal config, then further theming
  tmuxConfLocalThemed = builtins.replaceStrings ["[THEME_COLORS_TOKEN]"] [theme-colors] tmuxConfLocal;
  tmuxConfEllis = ''
    # -- Ellis' Settings -----------------------------------------------------------

    set -g mouse on

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
    run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux

    # set-option -sa terminal-overrides ',${term}:RGB'
    # set -ag terminal-overrides ",${term}:RGB"
    # set -g default-terminal "tmux-256color"
    set-option -sa terminal-features ',${term}:RGB'

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
 '';
  tmuxConf = tmuxConfLocalThemed + tmuxConfEllis + theme-status;
in
{
  home.packages = with pkgs; [
    tmux
    tmuxPlugins.continuum
    tmuxPlugins.cpu
    tmuxPlugins.open
    tmuxPlugins.resurrect
    tmuxPlugins.sensible
    tmuxPlugins.yank
  ];
  home.file.".tmux.conf".text = tmuxConfBase;
  home.file.".tmux.conf.local".text = if forceConfig then lib.mkForce tmuxConf else tmuxConf;
}
