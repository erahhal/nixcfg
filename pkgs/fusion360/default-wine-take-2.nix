# Documentation:
# https://github.com/cryinkfly/Autodesk-Fusion-360-for-Linux/wiki/Documentation
{ pkgs
, stdenv
, lib
, fetchurl
, makeDesktopItem
, imagemagick
, makeWrapper
, mkWindowsApp
, copyDesktopIcons
, copyDesktopItems
}:
let
  version = "v7.6.9";

  srcs = {
    fusion360-installer = fetchurl {
      url = "https://raw.githubusercontent.com/cryinkfly/Autodesk-Fusion-360-for-Linux/0df56158500bc1c8bb19c209e14747fef76b411f/files/builds/stable-branch/bin/install.sh";
      sha256 = "0c0qlw2qr1xyn3lax033pwh8q12l4x1l46vw7cajwcbklig5m9s1";
    };
  };

  icons = stdenv.mkDerivation {
    name = "fusion360";

    src = ./favicon.ico;

    nativeBuildInputs = [ imagemagick ];
    dontUnpack = true;

    installPhase = ''
      for n in 16 24 32 48 64 96 128 256; do
        size=$n"x"$n
        mkdir -p $out/hicolor/$size/apps
        convert $src\[2\] -resize $size $out/hicolor/$size/apps/fusion360.png
      done;
    '';
  };
  # fake pacman since script expects a standard distro
  # like Arch
  pacman = pkgs.writeShellScriptBin "pacman" ''
    exit 0
  '';
  runtime-paths = lib.makeBinPath [
    pacman
    # pkgs.wineWowPackages.waylandFull
    pkgs.wineWowPackages.stagingFull
    pkgs.winetricks
    pkgs.yad
    pkgs.cabextract
    pkgs.curl
    pkgs.samba
    pkgs.p7zip
    pkgs.ppp
  ];
  wine = pkgs.wineWowPackages.stagingFull;
in
mkWindowsApp rec {
  inherit version wine;
  pname = "fusion360";
  src = srcs.fusion360-installer;

  dontUnpack = true;

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${src} $out/bin/fusion360-installer
    chmod +x $out/bin/fusion360-installer
    ${pkgs.gnused}/bin/sed -i 's#/bin/bash#/usr/bin/env bash#g' $out/bin/fusion360-installer

    ln -s $out/bin/.launcher $out/bin/${pname}

    wrapProgram "$out/bin/${pname}" \
      --suffix PATH : ${runtime-paths} \
      --set FUSION_IDSDK false

    runHook postInstall
  '';

  winAppInstall = ''
    ${pkgs.bashInteractive}/bin/bash $out/bin/fusion360-installer
  '';

  winAppRun = ''
    ${pkgs.bashInteractive}/bin/bash $HOME/.fusion360/bin/launcher.sh
  '';

  desktopItems = let
    mimeTypes = [
      "x-world/x-3dmf"
      "application/x-3dmf"
    ];
  in [
    (makeDesktopItem rec {
      inherit mimeTypes;
      name = pname;
      exec = name;
      icon = name;
      desktopName = "Fusion 360";
      genericName = "3D Model Editor";
      categories = [
        "Development"
        "Graphics"
      ];
    })
  ];

  meta = with lib; {
    description = "Autodesk Fusion 360";
    homepage = "https://www.autodesk.com/products/fusion-360";
    license = licenses.unfree;
    maintainers = [ "erahhal" ];
    platforms = [
      "x86_64-linux"
    ];
  };
}
