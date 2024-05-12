{ inputs, pkgs, ... }:
let hyprland-patched = final: prev: {
  hyprland-patched = inputs.hyprland.packages.${pkgs.system}.hyprland.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./hyprland.patch
    ];
  });
};
in
{
  nixpkgs.overlays = [ hyprland-patched ];
}
