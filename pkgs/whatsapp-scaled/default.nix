{ pkgs }:

# See: https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages

pkgs.symlinkJoin {
  name = "whatsapp-for-linux";
  paths = [ pkgs.trunk.whatsapp-for-linux ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/whatsapp-for-linux \
      --set GDK_DPI_SCALE 1.25
  '';
}

