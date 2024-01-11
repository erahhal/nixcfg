# Documentation for install script:
# https://github.com/cryinkfly/Autodesk-Fusion-360-for-Linux/wiki/Documentation
#
# Troubleshooting error on install
# https://www.reddit.com/r/linuxquestions/comments/17d8vr2/how_do_i_get_fusion_360/

{ pkgs
, stdenv
, lib
, fetchurl
, makeDesktopItem
, imagemagick
, makeWrapper
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
in
stdenv.mkDerivation rec {
  name = "fusion360";
  src = srcs.fusion360-installer;

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${src} $out/bin/fusion360-installer
    chmod +x $out/bin/fusion360-installer
    ${pkgs.gnused}/bin/sed -i 's#/bin/bash#/usr/bin/env bash#g' $out/bin/fusion360-installer

    cat > $out/bin/fusion360 << EOF
      if [ -f ~/.fusion360/bin/launcher.sh ]; then
        ${pkgs.bashInteractive}/bin/bash ~/.fusion360/bin/launcher.sh
      else
        $out/bin/fusion360-installer
      fi
    EOF

    chmod +x $out/bin/fusion360

    wrapProgram "$out/bin/fusion360" \
      --suffix PATH : ${runtime-paths} \
      --set FUSION_IDSDK false \
      --set WINEPREFIX ~/.fusion360

    mkdir -p $out/share/icons
    ln -s ${icons}/hicolor $out/share/icons

    runHook postInstall
  '';

  desktopItems = let
    mimeTypes = [
      "x-world/x-3dmf"
    ];
  in [
    (makeDesktopItem rec {
      inherit mimeTypes;
      inherit name;

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
