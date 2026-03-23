{ pkgs, lib, stdenv, fetchurl, autoPatchelfHook, gcc-unwrapped }:

let
  version = "2.0.19";
  appName = "net.downloadhelper.coapp";

  generateManifest = { allowedSet ? {} }:
    pkgs.writeText "${appName}.json" (
      builtins.toJSON (lib.recursiveUpdate
        {
          name = appName;
          description = "Video DownloadHelper companion app";
          path = "DIR/bin/vdhcoapp";
          type = "stdio";
        }
        allowedSet
      )
    );

  firefoxManifest = generateManifest {
    allowedSet = { allowed_extensions = [ "weh-native-test@downloadhelper.net" "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" ]; };
  };
  chromeManifest = generateManifest {
    allowedSet = { allowed_origins = [ "chrome-extension://lmjnegcaeklhafolokijcfjliaokphfk/" ]; };
  };

in stdenv.mkDerivation rec {
  pname = "vdhcoapp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/aclap-dev/vdhcoapp/releases/download/v${version}/vdhcoapp-linux-x86_64.tar.bz2";
    sha256 = "sha256-l8Q7IPo23Pv0aMG2UgcbwgC9Z2M5uDdQZbLX+T/JWL0=";
  };

  sourceRoot = "vdhcoapp-${version}";

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    mkdir -p $out/bin
    install -m755 vdhcoapp $out/bin/vdhcoapp
    install -m755 ffmpeg $out/bin/vdhcoapp-ffmpeg
    install -m755 ffprobe $out/bin/vdhcoapp-ffprobe

    installManifest() {
      install -d $2
      cp $1 $2/${appName}.json
      substituteInPlace $2/${appName}.json --replace-fail DIR $out
    }
    installManifest ${chromeManifest}  $out/etc/opt/chrome/native-messaging-hosts
    installManifest ${chromeManifest}  $out/etc/chromium/native-messaging-hosts
    installManifest ${firefoxManifest} $out/lib/mozilla/native-messaging-hosts

    ln -s $out/bin/vdhcoapp $out/bin/${appName}
  '';

  meta = with lib; {
    description = "Companion application for the Video DownloadHelper browser add-on";
    homepage = "https://www.downloadhelper.net/";
    license = licenses.gpl2;
    platforms = [ "x86_64-linux" ];
  };
}
