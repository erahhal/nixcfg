{ hostParams, pkgs, ... }:
{
  # This theme switching mechanism heavily inspired by the following post:
  # https://discourse.nixos.org/t/home-manager-toggle-between-themes/32907

  # @TODOs
  # - Get Slack to change themes with system
  # - Automatically restart Discord if running, as it doesn't kick in without restart
  # - Fix tmux config split
  # - Fix other config splits (swaync, launcher.rasi, waybar)

  imports = [
    ./system-theme-dark.nix
  ];

  specialisation = {
    light-mode.configuration = {
      imports = [
        ./system-theme-light.nix
      ];
    };
  };

  home.packages = with pkgs; [
    (writeShellScriptBin "toggle-theme" (''
      set +e

      HOME_MANAGER=${pkgs.home-manager}/bin/home-manager
      PKILL=${pkgs.procps}/bin/pkill
      SYSTEMCTL=${pkgs.systemd}/bin/systemctl
      HEAD=${pkgs.coreutils}/bin/head
      TAIL=${pkgs.coreutils}/bin/tail
      RG=${pkgs.ripgrep}/bin/rg
      SYSTEM_THEME=$(cat ~/.system-theme)
      if [ "$SYSTEM_THEME" == "light-mode" ]; then
        GENERATION=$($HOME_MANAGER generations | $HEAD -2 | $TAIL -1 | $RG -o '/[^ ]*')
      else
        GENERATION=$($HOME_MANAGER generations | $HEAD -1 | $RG -o '/[^ ]*')/specialisation/light-mode
      fi
      "$GENERATION"/activate

    '' + (if hostParams.defaultSession == "sway" then ''
      SWAYMSG=${pkgs.sway}/bin/sway
      $PKILL waybar
      ## Using full path to tmux fails, so use one in $PATH
      tmux source-file ~/.tmux.conf
      $SYSTEMCTL --user restart swaynotificationcenter
      $SWAYMSG reload
    '' else "")))
  ];

  ## base16 guide
  # base00 - Default Background
  # base01 - Lighter Background (Used for status bars, line number and folding marks)
  # base02 - Selection Background
  # base03 - Comments, Invisibles, Line Highlighting
  # base04 - Dark Foreground (Used for status bars)
  # base05 - Default Foreground, Caret, Delimiters, Operators
  # base06 - Light Foreground (Not often used)
  # base07 - Light Background (Not often used)
  # base08 - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  # base09 - Integers, Boolean, Constants, XML Attributes, Markup Link Url
  # base0A - Classes, Markup Bold, Search Text Background
  # base0B - Strings, Inherited Class, Markup Code, Diff Inserted
  # base0C - Support, Regular Expressions, Escape Characters, Markup Quotes
  # base0D - Functions, Methods, Attribute IDs, Headings
  # base0E - Keywords, Storage, Selector, Markup Italic, Diff Changed
  # base0F - Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
}
