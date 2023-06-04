{ stdenv, fetchFromGitHub }:

let
  name = "chili";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "0.1.5";
  src = fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-chili";
    rev = version;
    sha256 = "036fxsa7m8ymmp3p40z671z163y6fcsa9a641lrxdrw225ssq5f3";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}
