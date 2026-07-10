{ pkgs, lib, stdenv, fetchurl, makeWrapper, gtk3, glib }:

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

  # The upstream release ships prebuilt binaries. `vdhcoapp` itself is a
  # vercel/pkg-bundled Node executable whose JS payload is appended *after*
  # the ELF sections. Running `strip` or `patchelf` on it rewrites the ELF
  # and discards/relocates that payload, which breaks it at runtime with
  # "Pkg: Error reading from file." (strip) or a SyntaxError in
  # pkg/prelude/bootstrap.js (patchelf).
  #
  # So we must NOT touch the binary. Instead we keep it byte-for-byte intact
  # and rely on the system-wide `programs.nix-ld` shim (the interpreter is
  # already /lib64/ld-linux-x86-64.so.2) to load it, injecting the runtime
  # libraries via NIX_LD_LIBRARY_PATH from a small wrapper:
  #   - libstdc++/libgcc_s  -> vdhcoapp itself
  #   - gtk3/glib           -> the bundled `filepicker` save-dialog helper
  #
  # converter.js also locates ffmpeg/ffprobe/filepicker as siblings named
  # exactly that in the binary's own directory (process.execPath), so all the
  # helper binaries are installed unrenamed next to vdhcoapp.
  nixLdLibraryPath = lib.makeLibraryPath [ stdenv.cc.cc.lib gtk3 glib ];

in stdenv.mkDerivation rec {
  pname = "vdhcoapp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/aclap-dev/vdhcoapp/releases/download/v${version}/vdhcoapp-linux-x86_64.tar.bz2";
    sha256 = "sha256-l8Q7IPo23Pv0aMG2UgcbwgC9Z2M5uDdQZbLX+T/JWL0=";
  };

  sourceRoot = "vdhcoapp-${version}";

  nativeBuildInputs = [
    makeWrapper
  ];

  # Never strip or patchelf the pkg-bundled binaries (see note above).
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    # Install the helper binaries unmodified, keeping their original names so
    # converter.js finds them as siblings of the vdhcoapp executable.
    mkdir -p $out/libexec/vdhcoapp
    for f in vdhcoapp ffmpeg ffprobe filepicker xdg-open; do
      install -m755 $f $out/libexec/vdhcoapp/$f
    done

    # Wrapper that provides the runtime libraries via nix-ld.
    makeWrapper $out/libexec/vdhcoapp/vdhcoapp $out/bin/vdhcoapp \
      --prefix NIX_LD_LIBRARY_PATH : "${nixLdLibraryPath}"

    installManifest() {
      install -d $2
      cp $1 $2/${appName}.json
      substituteInPlace $2/${appName}.json --replace-fail DIR $out
    }
    installManifest ${chromeManifest}  $out/etc/opt/chrome/native-messaging-hosts
    installManifest ${chromeManifest}  $out/etc/chromium/native-messaging-hosts
    installManifest ${firefoxManifest} $out/lib/mozilla/native-messaging-hosts

    ln -s $out/bin/vdhcoapp $out/bin/${appName}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Companion application for the Video DownloadHelper browser add-on";
    homepage = "https://www.downloadhelper.net/";
    license = licenses.gpl2;
    platforms = [ "x86_64-linux" ];
  };
}
