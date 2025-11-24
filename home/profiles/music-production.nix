{ pkgs, ... }:
{
  home.packages = with pkgs; [
    clonehero
  ];
}
