{ stdenv, fetchFromGitHub }:

let
  name = "slice";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "1.5.1";
  src = fetchFromGitHub {
    owner = "RadRussianRus";
    repo = "sddm-slice";
    rev = version;
    sha256 = "0b2ga0f4z61h7hfip2clfqdvr6friix1a8q6laiklfq7d4rm236l";
  };
  
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}
