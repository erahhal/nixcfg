{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  glib,
  glib-networking,
  gtk3,
  gdk-pixbuf,
  cairo,
  pango,
  webkitgtk_4_1,
  libsoup_3,
  libayatana-appindicator,
  libx11,
  libxi,
  procps,
  systemd,
  coreutils,
  # The unit the menu launcher brings up for the flash and stops on exit.
  # Defined by modules/programs/xteink-unlocker; if it's absent the launcher
  # degrades to just starting the GUI.
  helperUnit ? "xteink-unlocker-helper.service",
}:

# Upstream ships no Linux source build and no Nix packaging (github.com/OvermindDL1/
# xteink-unlocker is MIT but releases only prebuilt bundles), so this unpacks the
# official .deb. The URL is version-pinned, so the hash is stable across rebuilds.
stdenv.mkDerivation (finalAttrs: {
  pname = "xteink-unlocker";
  version = "0.2.38";

  src = fetchurl {
    url = "https://unlocker-releases.crosspointreader.com/v${finalAttrs.version}/XteinkUnlocker_${finalAttrs.version}_linux-x86_64.deb";
    hash = "sha256-HvrWMQ8CUJPPWzYQAKmT/a1YKDJSc8/2PmuHk4MHXio=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  # unlocker-app is a Tauri 2 (GTK3 + WebKitGTK 4.1) binary. unlocker-helper is a
  # plain Rust daemon needing only glibc/libgcc, which matters: the GUI's own
  # "install helper" path copies that file elsewhere and runs it as root, so it
  # must stay self-contained after patchelf.
  buildInputs = [
    glib
    gtk3
    gdk-pixbuf
    cairo
    pango
    webkitgtk_4_1
    libsoup_3
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    # The real binary lives in libexec so it keeps a stable path: the rpath fix
    # below has to run after autoPatchelf, which is after wrapping, so it can't
    # chase a $out/bin name that wrapping renames out from under it.
    install -Dm755 usr/bin/unlocker-app $out/libexec/xteink-unlocker/unlocker-app

    # Kept unwrapped and named exactly "unlocker-helper": the GUI locates a running
    # helper with `pgrep -x unlocker-helper`, which matches on the process name.
    install -Dm755 "usr/lib/Xteink Unlocker/unlocker-helper" $out/bin/unlocker-helper

    install -Dm755 ${./launcher.sh} $out/bin/xteink-unlocker

    install -Dm644 "usr/share/applications/Xteink Unlocker.desktop" \
      $out/share/applications/xteink-unlocker.desktop
    cp -r usr/share/icons $out/share/icons

    runHook postInstall
  '';

  # unlocker-app dlopens libX11/libXi (via libloading, after trying the Debian
  # multiarch dir) and libayatana-appindicator3 for its tray icon. None appear as
  # DT_NEEDED, so autoPatchelf neither resolves nor preserves them — queue the
  # rpath fix after autoPatchelf's own postFixup entry, which would shrink it away.
  preFixup = ''
    postFixupHooks+=("patchelf --add-rpath '${
      lib.makeLibraryPath [
        libx11
        libxi
        libayatana-appindicator
      ]
    }' '$out/libexec/xteink-unlocker/unlocker-app'")
  '';

  # Wrap by hand: wrapGAppsHook3 would also wrap $out/bin/unlocker-helper into a
  # shell script, which breaks both the `pgrep -x` name match and the GUI's
  # copy-the-helper-and-run-it-as-root flow.
  dontWrapGApps = true;

  postFixup = ''
    makeWrapper $out/libexec/xteink-unlocker/unlocker-app $out/bin/unlocker-app \
      "''${gappsWrapperArgs[@]}" \
      --set UNLOCKER_HELPER_PATH "$out/bin/unlocker-helper" \
      --prefix PATH : "${lib.makeBinPath [ procps ]}" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
      --set-default WEBKIT_DISABLE_DMABUF_RENDERER 1

    substituteInPlace $out/bin/xteink-unlocker \
      --subst-var-by systemctl ${systemd}/bin/systemctl \
      --subst-var-by sleep ${coreutils}/bin/sleep \
      --subst-var-by gui $out/bin/unlocker-app \
      --subst-var-by unit ${helperUnit}

    # Upstream's Exec is the bare "unlocker-app", which resolves to nothing from a
    # desktop launcher. Point it at the launcher rather than the GUI directly, so
    # opening it from the app menu also brings the helper up and back down.
    # Icon= stays a bare name so the installed hicolor theme resolves it at
    # whatever size the menu wants.
    substituteInPlace $out/share/applications/xteink-unlocker.desktop \
      --replace-fail Exec=unlocker-app "Exec=$out/bin/xteink-unlocker"
  '';

  meta = {
    description = "Install CrossPoint Reader on USB-locked Xteink e-readers over the air";
    longDescription = ''
      Xteink Unlocker serves community firmware (CrossPoint / CrossInk) to an Xteink
      X3/X4 from a Wi-Fi hotspot on this machine, intercepting the device's own OTA
      update check. It is the only route for international units, which ship with USB
      flashing disabled.

      The GUI talks to a root helper over a unix socket. Its built-in "install helper"
      button shells out to a hardcoded /usr/bin/pkexec, which does not exist on NixOS,
      so the "xteink-unlocker" launcher on the desktop entry handles the helper
      instead: it starts the helper unit (polkit prompts for the user's password),
      waits for the socket, runs the GUI, and stops the unit again on exit.

      The helper needs iptables (or nft) on PATH, reconfigures the Wi-Fi device into a
      hotspot over NetworkManager's D-Bus API, and spoofs DNS/NTP while running, which
      is why its lifetime is tied to the GUI rather than to boot.

      "unlocker-app" is the bare GUI with no helper management, for when the helper is
      being run by hand.
    '';
    homepage = "https://crosspointreader.com/unlocker";
    downloadPage = "https://crosspointreader.com/unlocker";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "xteink-unlocker";
  };
})
