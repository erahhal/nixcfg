{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  alsa-lib,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  glib,
  libdrm,
  libGL,
  libxkbcommon,
  libxml2_13,
  libxslt,
  libxcrypt-legacy,
  nspr,
  nss,
  xorg,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hyperbackup-explorer";
  version = "3.0.1-0156";

  src = fetchurl {
    url = "https://global.synologydownload.com/download/Utility/HyperBackupExplorer/${finalAttrs.version}/Linux/x86_64/HyperBackupExplorer-${finalAttrs.version}-linux.tar.bz2";
    hash = "sha256-WjbkvJyjHLhze+YwWflQahc0nBlUak/0L9F8xvCi4Ig=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    cups
    dbus
    expat
    fontconfig
    freetype
    glib
    libdrm
    libGL
    libxkbcommon
    libxml2_13
    libxslt
    libxcrypt-legacy
    nspr
    nss
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXau
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXdmcp
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/hyperbackup-explorer
    cp -r . $out/opt/hyperbackup-explorer/

    pushd $out/opt/hyperbackup-explorer >/dev/null
    rm -rf plugins/egldeviceintegrations
    rm -f plugins/platforms/libqeglfs.so plugins/platforms/libqlinuxfb.so
    rm -f plugins/imageformats/libqpdf.so
    rm -f plugins/sqldrivers/libqsqlmysql.so \
          plugins/sqldrivers/libqsqltds.so \
          plugins/sqldrivers/libqsqlodbc.so \
          plugins/sqldrivers/libqsqlpsql.so
    rm -f plugins/generic/libqlibinputplugin.so \
          plugins/generic/libqevdevtouchplugin.so
    popd >/dev/null

    mkdir -p $out/bin
    makeWrapper $out/opt/hyperbackup-explorer/HyperBackupExplorer $out/bin/hyperbackup-explorer \
      --set QT_QPA_PLATFORM xcb \
      --set QT_PLUGIN_PATH "$out/opt/hyperbackup-explorer/plugins" \
      --set QML2_IMPORT_PATH "" \
      --unset QT_QPA_PLATFORMTHEME \
      --unset QT_STYLE_OVERRIDE

    runHook postInstall
  '';

  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/hyperbackup-explorer/lib
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "hyperbackup-explorer";
      exec = "hyperbackup-explorer";
      desktopName = "Synology Hyper Backup Explorer";
      comment = "Browse and restore Synology Hyper Backup archives";
      categories = [ "Utility" "Archiving" ];
    })
  ];

  meta = {
    description = "Synology Hyper Backup Explorer - browse and restore Hyper Backup archives";
    homepage = "https://www.synology.com/support/download/HyperBackupExplorer";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "hyperbackup-explorer";
  };
})
