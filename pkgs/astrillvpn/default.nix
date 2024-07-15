{
  stdenv,
  lib,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  glib,
  gtk2-x11,
  libX11,
  openssl,
}: let
  version = "3.9.0.2180";
in
  stdenv.mkDerivation {
    pname = "astrillvpn";
    inherit version;

    src = ./astrill-setup-linux64_3.9.0.2180.deb;

    runtimeDependencies = [];

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = [
      glib
      gtk2-x11
      libX11
      openssl
    ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/etc $out/usr $out/share $out/bin

      mv etc/* $out/etc/
      mv usr/local $out/usr/
      mv usr/share $out/

      wrapProgram $out/usr/local/Astrill/astrill
      rm $out/usr/local/Astrill/astrill
      ln -s /run/wrappers/bin/astrill $out/bin/

      wrapProgram $out/usr/local/Astrill/asproxy
      rm $out/usr/local/Astrill/asproxy
      ln -s /run/wrappers/bin/asproxy $out/usr/local/Astrill/

      ln -s ${lib.getLib openssl}/lib/libcrypto.so $out/usr/local/Astrill/libcrypto.so.1.0.0

      sed -i "s|Exec=.*|Exec=$out/bin/astrill|" $out/share/applications/Astrill.desktop
      sed -i "s|Icon=.*|Icon=$out/usr/local/Astrill/astrillon.png|" $out/share/applications/Astrill.desktop

      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://www.astrill.com/";
      description = "Client for AstrillVPN";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = with maintainers; [ErrorNoInternet];
    };
  }
