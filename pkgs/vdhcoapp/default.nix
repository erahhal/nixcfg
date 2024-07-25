# FROM: https://codeberg.org/wolfangaukang/nix-agordoj/src/branch/main/pkgs/vdhcoapp

# To get working (there's probably a better way)
#   sudo net.downloadhelper.coapp install
#   mkdir -p ~/.mozilla/native-messaging-hosts
#   cp /usr/lib/mozilla/native-messaging-hosts/net.downloadhelper.coapp.json ~/.mozilla/native-messaging-hosts
#   sudo rm -rf /usr/lib/mozilla/native-messaging-hosts/net.downloadhelper.coapp.json

{ pkgs, lib, stdenv, nodejs, ffmpeg, glibc }:

let
  version = "2.0.19";

  src = pkgs.fetchFromGitHub {
    owner = "mi-g";
    repo = "vdhcoapp";
    rev = "v${version}";
    sha256 = "sha256-8xeZvqpRq71aShVogiwlVD3gQoPGseNOmz5E3KbsZxU=";
  };

  composition = import ./composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };

  nodeVdhcoapp = composition.nodeDependencies.override (old: {
    src = src;
    dontNpmInstall = true;
  });

  appName = "net.downloadhelper.coapp";

  generateManifest = { allowedSet ? {} }:
    pkgs.writeText "${appName}.json" (
      builtins.toJSON (lib.recursiveUpdate
        {
          name = appName;
          description = "Video DownloadHelper companion app";
          path = "DIR/${appName}";
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
  inherit version src;

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  buildInputs = [
    glibc
    nodeVdhcoapp
  ];

  patches = [
    (pkgs.substituteAll {
      src = ./0001-Make-the-app-runnable-without-pkg.patch;
      ffmpeg = "${ffmpeg}";
    })
  ];

  installPhase = ''
    mkdir -p $out/share/vdhcoapp
    chmod -x *.js *.json app/*.js assets/*
    cp -pr -t $out/share/vdhcoapp/ \
      app \
      assets \
      config.json \
      index.js \
      package.json \
      ${nodeVdhcoapp}/lib/node_modules
    installManifest() {
      install -d $2
      cp $1 $2/${appName}.json
      substituteInPlace $2/${appName}.json --replace DIR $out/share/vdhcoapp
    }
    installManifest ${chromeManifest}  $out/etc/opt/chrome/native-messaging-hosts
    installManifest ${chromeManifest}  $out/etc/chromium/native-messaging-hosts
    installManifest ${firefoxManifest} $out/lib/mozilla/native-messaging-hosts
    makeWrapper ${nodejs}/bin/node $out/share/vdhcoapp/${appName} \
      --add-flags $out/share/vdhcoapp/index.js \
      --set NODE_PATH $out/share/vdhcoapp/node_modules

    mkdir -p $out/bin
    ln -s $out/share/vdhcoapp/net.downloadhelper.coapp $out/bin/net.downloadhelper.coapp
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Companion application for the Video DownloadHelper browser add-on";
    homepage = "https://www.downloadhelper.net/";
    license = licenses.gpl2;
    platforms = nodejs.meta.platforms;
    maintainers = with maintainers; [ wolfangaukang ];
  };
}
