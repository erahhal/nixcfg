{ stdenv, fetchFromGitHub }:

let
  # multiple themes: adapta, arc, goodnight, mount, sober, zune
  name = "rokin05";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "edd130d0c0dddb382610af76967fe7cf8bff105b";
  src = fetchFromGitHub {
    # owner = "Rokin05";
    owner = "erahhal";
    repo = "SDDM-Themes";
    rev = version;
    sha256 = "0886xgwy5dwypfp1dj9krd5729vcimp2147c7wq3i5hh77bf1vx0";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src/src/* $out/share/sddm/themes/
  '';
}
