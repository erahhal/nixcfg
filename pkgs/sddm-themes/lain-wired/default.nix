{ stdenv, fetchFromGitHub }:

let
  name = "lain-wired";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "0.9.1";
  src = fetchFromGitHub {
    owner = "lll2yu";
    repo = "sddm-lain-wired-theme";
    rev = version;
    sha256 = "0b0jqsxk9w2x7mmdnxipmd57lpj6sjj7il0cnhy0jza0vzssry4j";
  };
  
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}

