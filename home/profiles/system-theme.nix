{ pkgs, userParams, ... }:
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
}
