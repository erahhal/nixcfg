{ pkgs, lib, forceConfig, theme-colors, theme-status, userParams, ... }:
let
  tmux-conf = pkgs.callPackage ../../pkgs/tmux-conf {};
  tmuxConfBase = builtins.readFile "${tmux-conf}/.tmux.conf";
  tmuxConfLocal = builtins.readFile "${tmux-conf}/.tmux.conf.local";
  term = if userParams.tty == "kitty" then "xterm-kitty" else "xterm-256color";
  xclip = "${pkgs.xclip}/bin/xclip";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";

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

    ## set options (alias for set-option)
    #    -g set globally for all windows and sessions that don't have a local setting for that option
    #    -w current window
    #    -p current pane
    #    -s server
    #    -u unset option
    #    -U unset option on panes of a window as well
    #    -o prevents setting an option that is already set
    #    -q suppresses errors
    #    -a append to string option

    ## Large scrollback buffer
    set-option -g history-limit 100000

    ## Enable mouse interactions
    # set -g mouse on

    ### TODO:
    ### Get rid of manual modification in tmux.conf of
    ### spacer_activity to a space and spacer_current to an empty string

    #-----------------------------------------------
    # Plugins
    #-----------------------------------------------

    ## "sensible" defaults
    run-shell ${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux

    ## CPU/GPU display
    # run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux

    ## Open links
    ## o        open
    ## ctrl-o   open with editor
    ## shift-s  search
    run-shell ${pkgs.tmuxPlugins.open}/share/tmux-plugins/open/open.tmux

    ## Resurrect - save and restore sessions
    set -g @resurrect-strategy-vim 'session'
    set -g @resurrect-strategy-nvim 'session'
    # set -g @resurrect-capture-pane-contents 'on'
    # set -g @resurrect-save-bash-history 'on'
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux

    ## Continuum - automatically save and restore using Resurrect
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '5' # minutes
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux

    ## Set terminal colors to support RGB truecolor
    set -as terminal-features ',${term}:RGB'

    ## Set default shell
    set -g default-shell /etc/profiles/per-user/${userParams.username}/bin/zsh

    ## Move status bar to the top
    set -g status-position top

    ## Enable clipboard
    set -g set-clipboard on

    # For sharing clipboard with vim
    # set -g focus-events on

    ## bind options (alias for bind-key)
    #    -N note
    #    -T key-table
    #         prefix table is default (C-a <key>)
    #         root table is keys pressed without prefix
    #    -n alias for -T root

    ## prefix2 allows a second prefix key
    ## Unsetting it here, and setting C-a as prefix key
    set -gu prefix2
    unbind C-a
    unbind C-b
    set -g prefix C-a
    bind C-a send-prefix

    ## Turns on vi-mode for buffer navigation
    # <space> to start selection
    # <enter> to copy text
    set -g mode-keys vi

    set -s copy-command '${wl-copy}'

    # Enable vim-like ctrl-v block selection
    bind -T copy-mode-vi 'C-v' send -X begin-selection \; send -X rectangle-toggle

    ## "send-keys" -X sends a command into copy mode
    ## @TODO: remove this once confirmed. Seems to only be needed for tmux 3.1 and older
    # bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"
    # bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"
    # bind -T copy-mode-vi C-j send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"

    # smart pane switching with awareness of vim splits
    bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-h) || tmux select-pane -L"
    bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-j) || tmux select-pane -D"
    bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-k) || tmux select-pane -U"
    bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iq 'vim' && tmux send-keys C-l) || tmux select-pane -R"
    # C-\ switches to last pane
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
