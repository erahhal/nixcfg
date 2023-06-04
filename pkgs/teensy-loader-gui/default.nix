{ pkgs, stdenv, fetchurl }:

let 
  teensy_version = "1.52";
  bin_sha256 = "1yivq1nr4rhmcqy0jw819b1s3ykqild40w5djmsp91n6lq79zj80";
in 
let
  teensy-loader-gui-bin = stdenv.mkDerivation rec {
    name = "teensy-loader-gui-bin";
    version = teensy_version;
    system = "x86_64-linux";
    src = fetchurl {
      url = "https://www.pjrc.com/teensy/teensy_linux64.tar.gz";
      sha256 = bin_sha256;
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
pkgs.buildFHSUserEnv {
  name = "teensy-loader-gui";
  targetPkgs = pkgs: with pkgs;
    [ 
      cairo
      gdk-pixbuf
      glib
      gnome2.pango
      gtk2-x11
      udev
      xorg.libSM
      xorg.libX11
      xorg.libXxf86vm

      teensy-loader-gui-bin
    ];
  runScript = "teensy-loader-gui-bin";
}
