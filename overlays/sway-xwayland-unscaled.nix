# Based off of:
## Patches Sway tag 1.9
# https://github.com/swaywm/sway/pull/5090
## Patches Wlroots tag 0.17.3
# https://github.com/swaywm/wlroots/pull/2064

{ ... }:
let sway-xwayland-unscaled = final: prev: {
  wlroots_0_17 = prev.wlroots_0_17.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./wlroots-xwayland-unscaled.patch
    ];
  });
  sway-unwrapped = prev.sway-unwrapped.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./sway-xwayland-unscaled.patch
    ];
  });
};
in
{
  nixpkgs.overlays = [ sway-xwayland-unscaled ];
}
