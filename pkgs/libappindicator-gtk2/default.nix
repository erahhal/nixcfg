# GTK 2 build of the Ayatana appindicator stack (libindicator, libdbusmenu,
# libappindicator).
#
# nixpkgs removed these on 2026-08-10 as part of its GTK 2 purge:
# libappindicator-gtk2 / libdbusmenu-gtk2 / libindicator-gtk2 are now `throw`
# aliases and only the GTK 3 builds remain. astrill is a GTK 2 binary that
# dlopens libappindicator.so.1 (the GTK 2 soname) for its StatusNotifierItem
# tray icon; without it the tray falls back to XEmbed, which doesn't work under
# Wayland. The GTK 3 flavour can't substitute — GTK 2 and GTK 3 abort when
# loaded into the same process.
#
# Rather than duplicate sources and hashes, reuse nixpkgs' current GTK 3
# packages and flip them to GTK 2 with overrideAttrs. The result matches the
# recipes nixpkgs shipped before the removal (same configure flags, inputs and
# patches — checked against the last-built derivations left in the store).
{
  lib,
  gtk2-x11,
  glib,
  dbus-glib,
  libdbusmenu,
  libindicator,
  libappindicator,
}:
let
  # The same gtk+-2 flavour astrillvpn links, so only one GTK 2 ends up in the
  # process.
  gtk2 = gtk2-x11;

  withGtk2 = map (f: if f == "--with-gtk=3" || f == "--disable-gtk" then "--with-gtk=2" else f);

  # `libdbusmenu` (withGtk3 = false) is the glib-only build; adding gtk2 and
  # --with-gtk=2 yields the old libdbusmenu-gtk2 (dbusmenu-gtk-0.4.pc).
  libdbusmenu-gtk2 = libdbusmenu.overrideAttrs (old: {
    pname = "libdbusmenu-gtk2";
    buildInputs = old.buildInputs ++ [ gtk2 ];
    configureFlags = withGtk2 old.configureFlags;
    meta = old.meta // {
      pkgConfigModules = old.meta.pkgConfigModules ++ [ "dbusmenu-gtk-0.4" ];
    };
  });

  libindicator-gtk2 = libindicator.overrideAttrs (old: {
    pname = "libindicator-gtk2";
    buildInputs = [ gtk2 ];
    configureFlags = withGtk2 old.configureFlags;
  });
in
libappindicator.overrideAttrs (old: {
  pname = "libappindicator-gtk2";
  propagatedBuildInputs = [
    gtk2
    libdbusmenu-gtk2
  ];
  buildInputs = [
    glib
    dbus-glib
    libindicator-gtk2
  ];
  configureFlags = withGtk2 old.configureFlags;
  meta = old.meta // {
    pkgConfigModules = [ "appindicator-0.1" ];
  };
  passthru = (old.passthru or { }) // {
    inherit libdbusmenu-gtk2 libindicator-gtk2;
  };
})
