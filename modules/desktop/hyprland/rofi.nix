{  pkgs, ... }:
{
  home.packages = with pkgs; [
    rofi
  ];

  programs.rofi = {
    enable = true;
    font = "Cascadia Code 10";
    # font = "Droid Sans Mono 14";
    terminal = "kitty";
    extraConfig = {
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
