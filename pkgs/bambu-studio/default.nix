{ pkgs
, stdenv
, lib
, fetchurl
, makeDesktopItem
, imagemagick
}:
let
  version = "v01.08.01.57";
  filename = "BambuStudio_linux_ubuntu_${version}.AppImage";

  srcs = {
    bambu-studio-appimage = fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/${version}/${filename}";
      sha256 = "0wm8chqqxg9gx0ank9j5dwlib0dzk6dbvg6ixr374fl839yficlr";
    };
  };

  icons = stdenv.mkDerivation {
    name = "bambu-studio";

    src = ./favicon.ico;

    nativeBuildInputs = [ imagemagick ];
    dontUnpack = true;

    installPhase = ''
      for n in 16 24 32 48 64 96 128 256; do
        size=$n"x"$n
        mkdir -p $out/hicolor/$size/apps
        convert $src\[2\] -resize $size $out/hicolor/$size/apps/bambu-studio.png
      done;
    '';
  };
in

# @TODO: Build from source: https://github.com/bambulab/BambuStudio
stdenv.mkDerivation rec {
  name = "bambu-studio";

  src = srcs.bambu-studio-appimage;

  dontUnpack = true;

  buildInputs = [ pkgs.makeWrapper ];

  # @TODO: determine why runtimeInputs doesn't work, and LD_PRELOAD is necessary below
  runtimeInputs = with pkgs; [
    webkitgtk
    glib-networking
    gst_all_1.gst-libav
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/appimage

    cp $src $out/appimage/${filename}

    LD_PRELOAD="${pkgs.webkitgtk}/lib/libwebkit2gtk-4.0.so.37"
    LD_PRELOAD="$LD_PRELOAD ${pkgs.webkitgtk}/lib/libjavascriptcoregtk-4.0.so.18"
    makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/bambu-studio \
      --add-flags "$out/appimage/${filename}" \
      --set GIO_MODULE_DIR ${pkgs.glib-networking}/lib/gio/modules \
      --set GST_PLUGIN_PATH ${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0 \
      --set LD_PRELOAD "$LD_PRELOAD"

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
      desktopName = "Bambu Studio";
      genericName = "Bambu Printer Studio App";
      categories = [
        "Development"
        "Graphics"
      ];
    })
  ];

  meta = with lib; {
    description = "Bambu Studio";
    homepage = "https://bambulab.com/en/download/studio";
    license = licenses.agpl3Only;
    maintainers = [ "erahhal" ];
    platforms = [
      "x86_64-linux"
    ];
  };
}
