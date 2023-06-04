{ pkgs, stdenv, fetchurl }:

let
  mcreator_version = "2022.1";
  mcreator_path_str = builtins.replaceStrings ["."] [""] mcreator_version;
  mcreator_build = "20510";
  archive_sha256 = "18dix4hszkgh4ll6p21l0990mis1s7yy82ak7jy1xf5fpxybf9my";
in
let
  mcreator-bin = stdenv.mkDerivation rec {
    name = "mcreator-bin";
    version = mcreator_version;
    system = "x86_64-linux";
    src = fetchurl {
      url = "https://github.com/MCreator/MCreator/releases/download/${mcreator_version}.${mcreator_build}/MCreator.${mcreator_version}.Linux.64bit.tar.gz";
      sha256 = archive_sha256;
    };
    phases = [ "installPhase" "fixupPhase" ];
    installPhase = ''
      tar xvzf $src
      mkdir -p $out/bin
      cp -R MCreator${mcreator_path_str}/* $out/bin
    '';
  };
in
pkgs.writeScriptBin "mcreator" ''
  #!/usr/bin/env bash

  cd ${mcreator-bin}/bin
  export CLASSPATH="./lib/mcreator.jar:./lib/*"
  ${pkgs.steam-run}/bin/steam-run ./jdk/bin/java --add-opens=java.base/java.lang=ALL-UNNAMED net.mcreator.Launcher "$1"
''
