{ pkgs, stdenv, fetchurl, bintools-unwrapped, ... }:

let
  hp-ams_version = "2.8.3-3056.1ubuntu16";
  archive_sha256 = "0aay2bs1vvjdy0k7nr9cfv4nzrrbimpsgl6zd1zpsc9ca85hck78";
in
stdenv.mkDerivation {
  pname = "hp-ams";
  version = hp-ams_version;

  src = fetchurl {
    url = "http://downloads.linux.hpe.com/SDR/repo/mcp/debian/pool/non-free/hp-ams_${hp-ams_version}_amd64.deb";
    sha256 = archive_sha256;
  };

  buildInputs = [ bintools-unwrapped ];

  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    ar x $src
    tar -xf data.tar.xz
    mkdir -p $out/bin
    cp sbin/amsHelper $out/bin
  '';

  postFixup = ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/bin/amsHelper
  '';
}
