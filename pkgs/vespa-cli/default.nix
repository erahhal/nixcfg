{ stdenv, fetchurl, bintools-unwrapped, ... }:

let
  version = "8.167.17";
  archive_sha256 = "1q99bynkkh5d3hiwnq5fdv3w0x4b2blsy27c0c6zv7yyvn9dr00c";
in
stdenv.mkDerivation {
  pname = "vespa-cli";
  version = version;

  src = fetchurl {
    url = "https://github.com/vespa-engine/vespa/releases/download/v${version}/vespa-cli_${version}_linux_amd64.tar.gz";
    sha256 = archive_sha256;
  };

  buildInputs = [ bintools-unwrapped ];

  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    tar xvzf $src
    mkdir -p $out/bin
    cp vespa-cli_${version}_linux_amd64/bin/vespa $out/bin
    cp -R vespa-cli_${version}_linux_amd64/share $out
  '';
}
