## Pulse Secure VPN for Netflix
#
# Instruction: https://netflix.zendesk.com/hc/en-us/articles/1500002301941
# Linux Specific: https://netflix.zendesk.com/hc/en-us/articles/360060929814

{ pkgs, stdenv, unzip, dpkg, bzip2, openssl, makeDesktopItem, ... }:

let
  pulse_version = "9.1r15.0-b15819";
  pulse-secure-pkg = stdenv.mkDerivation {
    pname = "pulse-secure";
    version = pulse_version;

    # From: https://drive.google.com/drive/folders/1YzrbvRGNyKNNHqEKmSgDxla_poGxe2le
    src = ./ps-pulse-linux-${pulse_version}-64bit-installer.deb;

    buildInputs = [ unzip bzip2 dpkg ];

    phases = [ "installPhase" "fixupPhase" ];

    installPhase = ''
      ar x $src
      tar -xf data.tar.xz
      mkdir -p $out/share
      cp -R opt/pulsesecure/* $out/
      cp -R usr/share/man $out/share/
    '';

#     postFixup = ''
#       patchelf \
#         --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
#         $out/bin/cctk
#     '';

    desktopItems = [
      (makeDesktopItem {
        desktopName = "PulseUI";
        name = "pulseUI";
        # TODO - fix path
        exec = "pulseUI";
        comment = "LINUX UI CLIENT";
        # TODO - fix path
        # icon = "pulse.png";
        categories = [
          "Utility"
        ];
        startupWMClass = "pulseUI";
      })
    ];
  };
  lib-path = "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pulse-secure-pkg}/lib/dispatch:${pulse-secure-pkg}/lib/dsOpenSSL:${pulse-secure-pkg}/lib/JUNS:${pulse-secure-pkg}/bin";
  targetPkgs = pkgs: with pkgs;
    [
      atk
      atkmm
      cairo
      cairomm
      gdk-pixbuf
      glib
      glibmm
      gtk3
      gtkmm3
      libbsd
      libcef
      libsigcxx
      libsoup
      libuuid
      xorg.libX11
      openssl
      pango
      pangomm
      webkitgtk

      pulse-secure-pkg
    ];
  cefBrowser-wrapper = pkgs.writeShellScriptBin "cefBrowser-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/cefBrowser $@";
  cefBrowser = pkgs.buildFHSUserEnv {
    name = "cefBrowser";
    targetPkgs = targetPkgs;
    runScript = "${cefBrowser-wrapper}/bin/cefBrowser-wrapper";
  };
  cefSubProcess-wrapper = pkgs.writeShellScriptBin "cefSubProcess-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/cefSubProcess $@";
  cefSubProcess = pkgs.buildFHSUserEnv {
    name = "cefSubProcess";
    targetPkgs = targetPkgs;
    runScript = "${cefSubProcess-wrapper}/bin/cefSubProcess-wrapper";
  };
  jamCommand-wrapper = pkgs.writeShellScriptBin "jamCommand-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/jamCommand $@";
  jamCommand = pkgs.buildFHSUserEnv {
    name = "jamCommand";
    targetPkgs = targetPkgs;
    runScript = "${jamCommand-wrapper}/bin/jamCommand-wrapper";
  };
  pulselauncher-wrapper = pkgs.writeShellScriptBin "pulselauncher-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/pulselauncher $@";
  pulselauncher = pkgs.buildFHSUserEnv {
    name = "pulselauncher";
    targetPkgs = targetPkgs;
    runScript = "${pulselauncher-wrapper}/bin/pulselauncher-wrapper";
  };
  pulsesecure-wrapper = pkgs.writeShellScriptBin "pulsesecure-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/pulsesecure $@";
  pulsesecure = pkgs.buildFHSUserEnv {
    name = "pulsesecure";
    targetPkgs = targetPkgs;
    runScript = "${pulsesecure-wrapper}/bin/pulsesecure-wrapper";
  };
  pulseUI-wrapper = pkgs.writeShellScriptBin "pulseUI-wrapper" "${lib-path} ${pulse-secure-pkg}/bin/pulseUI $@";
  pulseUI = pkgs.buildFHSUserEnv {
    name = "pulseUI";
    targetPkgs = targetPkgs;
    runScript = "${pulseUI-wrapper}/bin/pulseUI-wrapper";
  };
in
pkgs.symlinkJoin {
  name = "pulse-secure";
  paths = [
    cefBrowser
    cefSubProcess
    jamCommand
    pulselauncher
    pulsesecure
    pulseUI
  ];
}

