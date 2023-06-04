{ pkgs, stdenv, fetchurl }:

let
  ia_version = "3.0.2";
  archive_sha256 = "1w9q1ys0g3q7mg1bwsj46c05vhkcq0g388s32w2xqypyll5aly9r";
in
stdenv.mkDerivation rec {
  name = "ia";
  version = ia_version;
  src = fetchurl {
    url = "https://archive.org/download/ia-pex/ia-${ia_version}-py3-none-any.pex";
    sha256 = archive_sha256;
  };
  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/ia
    chmod +x $out/bin/ia
  '';
}
