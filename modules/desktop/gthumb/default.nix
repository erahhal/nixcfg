{  pkgs, ... }:
{
  home.packages = with pkgs; [
    gthumb
  ];

  xdg.configFile."gthumb/shortcuts.xml".source = ./shortcuts.xml;
}
