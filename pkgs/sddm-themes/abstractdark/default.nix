{ stdenv }:

let
  name = "abstrackdark";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "0.1";
  src = ./theme;
  
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}
