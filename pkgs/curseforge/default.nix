{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
  unzip,
}:

let
  # First, create a derivation that extracts the AppImage from the zip
  appimageFromZip = stdenv.mkDerivation {
    name = "curseforge-appimage";
    src = fetchurl {
      url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.zip";
      hash = "sha256-EdX0wpFWWYeNOEuFx5iDwnekMosNXGMKnMoN43y7+5A=";
    };

    nativeBuildInputs = [ unzip ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      # Find and copy the AppImage
      appimage=$(find . -name "*.AppImage" -type f | head -1)
      cp "$appimage" $out
    '';
  };
in
let
  version = "1.281.1.26848";
  pname = "curseforge";

  src = appimageFromZip;

  # Extract contents for desktop files, icons, etc.
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;
  extraInstallCommands = ''
    # Fix the desktop file to point to the correct binary
    install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop

    # Replace the Exec line in the desktop file to point to our wrapped binary
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/${pname}" \
      --replace "Exec=AppRun --no-sandbox" "Exec=$out/bin/${pname}"

    # Install icon
    install -m 444 -D ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
  '';

  meta = {
    description = "Curseforge";
    homepage = "https://www.curseforge.com/";
    downloadPage = "https://www.curseforge.com/download/app";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
