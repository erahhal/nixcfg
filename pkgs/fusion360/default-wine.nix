{ pkgs
, stdenv
, lib
, fetchurl
, mkWindowsApp
, makeDesktopItem
, imagemagick
, copyDesktopIcons
, copyDesktopItems
, winetricks
}:
let
  version = "v7.6.9";

  srcs = {
    fusion360-installer = fetchurl {
      url = "https://github.com/cryinkfly/Autodesk-Fusion-360-for-Linux/blob/0df56158500bc1c8bb19c209e14747fef76b411f/files/builds/stable-branch/bin/install.sh";
      sha256 = "17n084iavsqcqi24h7fhrislvzmlzm8602lqzn1vljjdy01gh22p";
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

  wine = pkgs.wineWowPackages.waylandFull;
in mkWindowsApp rec {
  inherit version wine;

  pname = "fusion360";

  src = srcs.fusion360-installer;

  runtimeInputs = with pkgs; [
    wineWowPackages.waylandFull
    winetricks
    yad
  ];

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];
  dontUnpack = true;

  winAppInstall = ''
    ${pkgs.bashInteractive}/bin/bash ${src}
  '';

  winAppRun = ''
    ${pkgs.bashInteractive}/bin/bash ${src}
   # rm -fR "$WINEPREFIX/drive_c/users/$USER/Application Data/fusion360"
   # mkdir -p "$HOME/.fusion360"
   # ln -s -v "$HOME/.fusion360" "$WINEPREFIX/drive_c/users/$USER/Application Data/"
   #
   # wine start /unix "$WINEPREFIX/drive_c/Program Files/fusion360/fusion360.exe" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/fusion360
    mkdir -p $out/share/icons
    ln -s ${icons}/hicolor $out/share/icons

    runHook postInstall
  '';

  desktopItems = let
    # See for full list of file types:
    # https://help.autodesk.com/view/fusion360/ENU/?guid=TPD-SUPPORTED-FILE-FORMATS
    mimeTypes = [
      "x-world/x-3dmf"
      "application/x-3dmf"
    ];
  in [
    (makeDesktopItem {
      inherit mimeTypes;

      name = "fusion360";
      exec = pname;
      icon = pname;
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
      "i686-linux"
    ];
  };
}
