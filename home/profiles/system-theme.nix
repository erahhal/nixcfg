{ config, pkgs, ... }:
{
  # This theme switching mechanism heavily inspired by the following post:
  # https://discourse.nixos.org/t/home-manager-toggle-between-themes/32907

  imports = [
    ./system-theme-dark.nix
  ];

  # @TODO: move this into flake.nix,
  # loading configuration.nix with an argument as
  # to which theme is used
  specialisation = {
    light-mode.configuration = {
      imports = [
        ./system-theme-light.nix
      ];
    };
  };

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "toggle-theme";
      runtimeInputs = with pkgs; [ home-manager coreutils ripgrep ];
      text =
        ''
          SYSTEM_THEME=$(cat ~/.system-theme)
          if [ "$SYSTEM_THEME" == "light-mode" ]; then
            "$(home-manager generations | head -2 | tail -1 | rg -o '/[^ ]*')"/activate
          else
            "$(home-manager generations | head -1 | rg -o '/[^ ]*')"/specialisation/light-mode/activate
          fi
          tmux source-file ~/.tmux.conf
        '';
    })
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
