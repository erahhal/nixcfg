{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  glib,
  gtk2-x11,
  gdk-pixbuf,
  pango,
  cairo,
  atk,
  xorg,
  libappindicator-gtk2,
  # Runtime tools astrill shells out to via /bin/sh (with a bare PATH).
  coreutils,
  bash,
  gnugrep,
  gnused,
  nettools,
  iproute2,
  e2fsprogs,
  procps,
  psmisc,
  dnsmasq,
  iptables,
  xdg-utils,
}:
let
  # Placed on the launcher's PATH so astrill's shell-outs resolve: chattr/lsattr
  # (resolv.conf immutability), route/ifconfig + ip (routing/detection), sysctl,
  # killall (`killall -HUP dnsmasq`), dnsmasq, iptables, cat/cp/rm, grep/sed,
  # xdg-open. (asovpnc's incompatible `--iproute` is stripped by asovpnc-wrapper.sh,
  # not by withholding `ip` — the launcher inherits the session PATH which has it.)
  runtimeTools = [
    coreutils
    bash
    gnugrep
    gnused
    nettools
    iproute2
    e2fsprogs
    procps
    psmisc
    dnsmasq
    iptables
    xdg-utils
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "astrillvpn";
  version = "3.10.0-3073";

  # Astrill only serves the latest build at this URL, so the hash must be bumped
  # when they publish a new version (the build fails loudly on mismatch). Same
  # rolling-URL + pinned-hash approach as pkgs/curseforge.
  src = fetchurl {
    url = "https://www.astrilldownloads.com/astrill-setup-linux64.deb";
    hash = "sha256-pxAAkyRN/j0g4hMenuR/4/eThkxjXrth/Q86BfNAN8g="; # 3.10.0-3073
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  # astrill is a GTK2 binary; the helper connectors (asovpnc/aswgvpnc/openweb) and
  # the bundled libcrypto/libssl (OpenSSL 1.0, kept as-is) need only glibc. The
  # theme is PNG-only and uses GTK2's built-in "pixmap" engine, so gdk-pixbuf's
  # default PNG loader and gtk2's bundled engines are found without env wrapping.
  buildInputs = [
    glib
    gtk2-x11
    gdk-pixbuf
    pango
    cairo
    atk
    xorg.libX11
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/usr/local $out/share/applications $out/bin
    cp -r usr/local/Astrill $out/usr/local/
    install -Dm644 usr/share/applications/Astrill.desktop \
      $out/share/applications/Astrill.desktop

    # PATH/desktop entrypoint. astrill needs three things the raw binary lacks:
    #   1. cap_net_admin/cap_net_raw -> exec the NixOS capability wrapper.
    #   2. a populated PATH -> it shells out to chattr/route/ifconfig/sysctl/
    #      killall/dnsmasq/ip/cp/cat via /bin/sh, otherwise with a bare PATH.
    #   3. --noasproxycheck -> its startup check tries to re-privilege asproxy by
    #      rewriting the on-disk binary, impossible from the read-only Nix store
    #      (the asproxy wrapper already grants caps), so the check is a false
    #      negative and pops "ASProxy component has insufficient privilege".
    # Hand-written (not makeWrapper) because the wrapper target only exists at
    # runtime under /run/wrappers and makeBinaryWrapper asserts it exists.
    {
      echo '#!/bin/sh'
      echo 'export PATH=/run/wrappers/bin:${lib.makeBinPath runtimeTools}''${PATH:+:''$PATH}'
      echo 'exec /run/wrappers/bin/astrill --noasproxycheck "''$@"'
    } > $out/bin/astrill
    chmod +x $out/bin/astrill

    # asproxy is Astrill's privileged network helper. astrill spawns the sibling
    # "<dir>/asproxy"; point it at the capability wrapper the NixOS module creates,
    # keeping the real (static) binary for the wrapper to source. The wrapper
    # preserves argv and execs .asproxy-real, which finds liblsp via /proc/self/exe.
    mv $out/usr/local/Astrill/asproxy $out/usr/local/Astrill/.asproxy-real
    ln -s /run/wrappers/bin/asproxy $out/usr/local/Astrill/asproxy

    # Wrap asovpnc (the bundled OpenVPN) to strip the unsupported `--iproute`
    # option astrill passes; otherwise OpenVPN aborts before opening its management
    # socket. See asovpnc-wrapper.sh. astrill execs the sibling, which execs the
    # real binary kept alongside as .asovpnc-real.
    mv $out/usr/local/Astrill/asovpnc $out/usr/local/Astrill/.asovpnc-real
    install -Dm755 ${./asovpnc-wrapper.sh} $out/usr/local/Astrill/asovpnc
    substituteInPlace $out/usr/local/Astrill/asovpnc \
      --replace-fail @REAL@ $out/usr/local/Astrill/.asovpnc-real

    runHook postInstall
  '';

  preFixup = ''
    # Let autoPatchelf resolve Astrill's bundled .so siblings (the OpenSSL 1.0 ABI
    # it dlopens) instead of dragging in nixpkgs openssl. Must run before autoPatchelf.
    addAutoPatchelfSearchPath $out/usr/local/Astrill

    # astrill dlopens its bundled libcrypto.so/libssl.so by bare name, so the
    # Astrill dir must be on its RUNPATH. It also dlopens libappindicator.so.1 for
    # its (preferred) StatusNotifierItem tray icon, falling back to legacy XEmbed
    # GtkStatusIcon (which doesn't work under Wayland) when it's absent — so add
    # the GTK2 appindicator too (it links the same gtk+-2.24.33, no double-load).
    # autoPatchelf would shrink these away, so queue the fix on postFixupHooks
    # *after* autoPatchelf's own entry (registered at setup time).
    postFixupHooks+=("patchelf --add-rpath '$out/usr/local/Astrill:${libappindicator-gtk2}/lib' '$out/usr/local/Astrill/astrill'")
  '';

  postFixup = ''
    substituteInPlace $out/share/applications/Astrill.desktop \
      --replace-fail Exec=/usr/local/Astrill/astrill Exec=$out/bin/astrill \
      --replace-fail Icon=/usr/local/Astrill/astrillon.png Icon=$out/usr/local/Astrill/astrillon.png
  '';

  meta = {
    description = "Astrill VPN client";
    homepage = "https://www.astrill.com/";
    license = lib.licenses.unfree; # already allowed repo-wide
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "astrill";
  };
})
