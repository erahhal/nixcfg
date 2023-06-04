{ stdenv, fetchFromGitHub }:

let
  name = "sugar-dark";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "1.2";
  src = fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-sugar-dark";
    rev = "v${version}";
    sha256 = "0gx0am7vq1ywaw2rm1p015x90b75ccqxnb1sz3wy8yjl27v82yhb";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}
