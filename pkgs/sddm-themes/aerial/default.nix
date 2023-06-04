{ stdenv, fetchFromGitHub }:

let
  name = "aerial";
in
stdenv.mkDerivation rec {
  pname = name;
  version = "0.1";
  src = fetchFromGitHub {
    owner = "3ximus";
    repo = "aerial-sddm-theme";
    rev = "218199a298ee21cf428efa2521561093d7450acc";
    sha256 = "1yxqm3kqf1q00ihgr8zv6x15hf6dkqgj67fmhih091bx1cpk6d53";
  };
  
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/${name}
  '';
}
