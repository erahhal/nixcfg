{ pkgs, stdenv, fetchurl }:

let
  teensy_version = "1.52";
in
let
  teensy-loader-gui-bin = stdenv.mkDerivation rec {
    name = "teensy-loader-gui-bin";
    version = teensy_version;
    system = "x86_64-linux";
    src = fetchurl {
      url = "https://www.pjrc.com/teensy/teensy_linux64.tar.gz";
      hash = "sha256-PHcq6jVWkSLjtMy/wv674BSow1ajgJ0/haj+V7xW+bk=";
    };
    phases = [ "installPhase" "fixupPhase" ];
    installPhase = ''
      tar xvzf $src
      mkdir -p $out/bin
      cp * $out/bin
      ln -s $out/bin/teensy $out/bin/teensy-loader-gui-bin
    '';
  };
in
# @TODO: try patching and including required packages instead
pkgs.buildFHSEnv {
  name = "teensy-loader-gui";
  targetPkgs = pkgs: with pkgs;
    [
      cairo
      gdk-pixbuf
      glib
      pango
      gtk2-x11
      udev
      libsm
      libx11
      libxxf86vm

      teensy-loader-gui-bin
    ];
  runScript = "teensy-loader-gui-bin";
}
