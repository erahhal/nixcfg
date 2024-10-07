{ pkgs }:

# See: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages

pkgs.symlinkJoin {
  name = "gnome-calculator";
  paths = [ pkgs.gnome-calculator ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/gnome-calculator \
      --set GDK_DPI_SCALE 2
  '';
}

