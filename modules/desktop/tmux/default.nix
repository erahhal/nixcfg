{ pkgs, lib, config, userParams, ... }:
let
  colors = config.lib.stylixScheme or config.lib.stylix.colors or {};
  hasColors = colors != {};

  # Powerline rounded glyphs for tmux pill-shaped tabs
  plRoundLeft = builtins.fromJSON ''"\\uE0B6"'';   #
  plRoundRight = builtins.fromJSON ''"\\uE0B4"'';   #
  windowIcon = builtins.fromJSON ''"\\uF2D0"'';     # Nerd Font window icon

  # gpakosz tmux theme colors driven by Stylix base16 palette
  theme-colors = lib.optionalString hasColors ''
    tmux_conf_theme_colour_1="#${colors.base00}"
    tmux_conf_theme_colour_2="#${colors.base02}"
    tmux_conf_theme_colour_3="#${colors.base03}"
    tmux_conf_theme_colour_4="#${colors.base0D}"
    tmux_conf_theme_colour_5="#${colors.base0A}"
    tmux_conf_theme_colour_6="#${colors.base01}"
    tmux_conf_theme_colour_7="#${colors.base05}"
    tmux_conf_theme_colour_8="#${colors.base00}"
    tmux_conf_theme_colour_9="#${colors.base0A}"
    tmux_conf_theme_colour_10="#${colors.base0E}"
    tmux_conf_theme_colour_11="#${colors.base0B}"
    tmux_conf_theme_colour_12="#${colors.base03}"
    tmux_conf_theme_colour_13="#${colors.base05}"
    tmux_conf_theme_colour_14="#${colors.base00}"
    tmux_conf_theme_colour_15="#${colors.base00}"
    tmux_conf_theme_colour_16="#${colors.base08}"
    tmux_conf_theme_colour_17="#${colors.base06}"
  '';
  # gpakosz theme variables — gpakosz _apply_theme() reads these shell variables and
  # generates tmux settings. Direct `set -g` commands get OVERRIDDEN by gpakosz.
  # The window pill shape works because: left_separator_main is empty (default),
  # and window_status_current_format contains the full format with  and  chars.
  theme-status = lib.optionalString hasColors ''
    # Message
    tmux_conf_theme_message_fg="#${colors.base0A}"
    tmux_conf_theme_message_bg="#${colors.base00}"
    tmux_conf_theme_message_attr="bold"
    tmux_conf_theme_message_command_fg="#${colors.base0A}"
    tmux_conf_theme_message_command_bg="#${colors.base00}"
    tmux_conf_theme_message_command_attr="bold"

    # Pane borders — use gpakosz defaults (colour_2 for inactive, colour_4/cyan for active)
    # No override needed; colour_2=base01, colour_4=base0D (teal)

    # Status bar
    tmux_conf_theme_status_fg="#${colors.base05}"
    tmux_conf_theme_status_bg="#${colors.base00}"

    # Status left: icon, session name, session-attached pill
    tmux_conf_theme_status_left="#[fg=#${colors.base00},bg=#${colors.base00}] #[fg=#${colors.base0D},bg=#${colors.base00}] ${windowIcon} #[fg=#${colors.base03},bg=#${colors.base00}] #S #[fg=#${colors.base0B},bg=#${colors.base00}]${plRoundLeft}#[fg=#${colors.base00},bg=#${colors.base0B},bold]#{session_attached}#[fg=#${colors.base0B},bg=#${colors.base00}]${plRoundRight} "
    tmux_conf_theme_status_left_length="100"

    # Status right: battery, time, date, username pill, hostname pill
    tmux_conf_theme_status_right_fg="#${colors.base05}"
    tmux_conf_theme_status_right_bg="#${colors.base00}"
    tmux_conf_theme_status_right=" #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status,#{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #[fg=#${colors.base00},bg=#${colors.base0B},bold] #{username} #[bg=#${colors.base08}]#{root}#[fg=#${colors.base00},bg=#${colors.base0D},bold] #{hostname} "

    # Window status — current window as rounded pill using  (U+E0B6) and  (U+E0B4)
    tmux_conf_theme_window_status_fg="#${colors.base04}"
    tmux_conf_theme_window_status_bg="#${colors.base00}"
    tmux_conf_theme_window_status_current_fg="#${colors.base00}"
    tmux_conf_theme_window_status_current_bg="#${colors.base0D}"
    tmux_conf_theme_window_status_current_attr="bold"
    tmux_conf_theme_window_status_current_format="#[fg=#${colors.base0D},bg=#${colors.base00}]${plRoundLeft}#[fg=#${colors.base00},bg=#${colors.base0D},bold]#I:#W#[fg=#${colors.base0D},bg=#${colors.base01}]${plRoundRight}"
  '';
  tmux-conf = pkgs.callPackage ../../../pkgs/tmux-conf {};
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

    # Clipboard copy: override gpakosz copy-selection with copy-pipe to use copy-command
    bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
    bind -T copy-mode y send-keys -X copy-pipe-and-cancel

    # Copy and paste in place (replaces tmux-yank Y binding)
    bind -T copy-mode-vi Y send-keys -X copy-pipe-and-cancel \; paste-buffer -p
    bind -T copy-mode Y send-keys -X copy-pipe-and-cancel \; paste-buffer -p

    # Copy without trailing newline (replaces tmux-yank ! binding)
    bind -T copy-mode-vi ! send-keys -X copy-pipe-and-cancel "tr -d '\\n' | ${wl-copy}"
    bind -T copy-mode ! send-keys -X copy-pipe-and-cancel "tr -d '\\n' | ${wl-copy}"

    ## "send-keys" -X sends a command into copy mode
    ## @TODO: remove this once confirmed. Seems to only be needed for tmux 3.1 and older
    # bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"
    # bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"
    # bind -T copy-mode-vi C-j send-keys -X copy-pipe-and-cancel "${xclip} -i -f -selection primary | ${xclip} -i -selection clipboard"

    # smart pane switching with awareness of vim splits
    # - Local vim: vim-tmux-navigator handles edge fallthrough
    # - Remote vim (SSH/et): title contains edge markers (~L, ~R, ~T, ~B) - fallthrough if at edge
    bind -n C-h run-shell 'cmd="$(tmux display-message -p "#{pane_current_command}")"; title="$(tmux display-message -p "#{pane_title}")"; if echo "$cmd" | grep -iqE "(vim|nvim)"; then tmux send-keys C-h; elif echo "$title" | grep -iqE "(vim|nvim)"; then if echo "$title" | grep -q "~L"; then tmux select-pane -L; else tmux send-keys C-h; fi; else tmux select-pane -L; fi'
    bind -n C-j run-shell 'cmd="$(tmux display-message -p "#{pane_current_command}")"; title="$(tmux display-message -p "#{pane_title}")"; if echo "$cmd" | grep -iqE "(vim|nvim)"; then tmux send-keys C-j; elif echo "$title" | grep -iqE "(vim|nvim)"; then if echo "$title" | grep -q "~B"; then tmux select-pane -D; else tmux send-keys C-j; fi; else tmux select-pane -D; fi'
    bind -n C-k run-shell 'cmd="$(tmux display-message -p "#{pane_current_command}")"; title="$(tmux display-message -p "#{pane_title}")"; if echo "$cmd" | grep -iqE "(vim|nvim)"; then tmux send-keys C-k; elif echo "$title" | grep -iqE "(vim|nvim)"; then if echo "$title" | grep -q "~T"; then tmux select-pane -U; else tmux send-keys C-k; fi; else tmux select-pane -U; fi'
    bind -n C-l run-shell 'cmd="$(tmux display-message -p "#{pane_current_command}")"; title="$(tmux display-message -p "#{pane_title}")"; if echo "$cmd" | grep -iqE "(vim|nvim)"; then tmux send-keys C-l; elif echo "$title" | grep -iqE "(vim|nvim)"; then if echo "$title" | grep -q "~R"; then tmux select-pane -R; else tmux send-keys C-l; fi; else tmux select-pane -R; fi'
    # C-\ switches to last pane
    bind -n 'C-\' run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(vim|nvim)' && tmux send-keys 'C-\\') || (tmux display-message -p '#{pane_title}' | grep -iqE '(vim|nvim)' && tmux send-keys 'C-\\') || tmux select-pane -l"

    set -g extended-keys on
    set -g extended-keys-format csi-u
 '';

  tmuxConf = theme-colors + tmuxConfLocalThemed + tmuxConfEllis + theme-status;
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
  home.file.".tmux.conf".text = tmuxConfBase;
  home.file.".tmux.conf.local".text = tmuxConf;
}
