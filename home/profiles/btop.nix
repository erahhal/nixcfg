{ lib, pkgs, ... }:
let
  btopConfBase = builtins.readFile ./btop/btop.conf;
in
{
  home.packages = [
    pkgs.btop
  ];

  ## mkBefore makes sure this is at the top
  ## theming appends to the end of this file
  xdg.configFile."btop/btop.conf".text = lib.mkBefore btopConfBase;
}
