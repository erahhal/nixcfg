{  pkgs, ... }:
{
  home.packages = with pkgs; [
    rofi
  ];

  programs.rofi = {
    enable = true;
    # font/terminal/extraConfig were folded into settings by home-manager
    settings = {
      font = "Cascadia Code 10";
      # font = "Droid Sans Mono 14";
      terminal = "kitty";
      show-icons = false;
      display-drun = "Apps";
      drun-display-format = "{name}";
      scroll-method = 0;
      disable-history = false;
      sidebar-mode = true;
    };
    theme = "default.rasi";
  };

  xdg.configFile."rofi/default.rasi".source = ./rofi/default.rasi;
}
