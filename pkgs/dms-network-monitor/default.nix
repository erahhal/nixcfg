{ stdenv }:

stdenv.mkDerivation {
  pname = "dms-network-monitor";
  version = "1.0.0";
  src = ./plugin;
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
  '';
}
