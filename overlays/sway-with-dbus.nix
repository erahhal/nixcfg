{ ... }:
let sway-with-dbus = final: prev: {
  sway = prev.sway.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./sway-with-dbus/sway-desktop.patch
    ];
  });
};
in
{
  nixpkgs.overlays = [ sway-with-dbus ];
}
