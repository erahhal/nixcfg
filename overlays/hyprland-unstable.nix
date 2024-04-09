{ ... }:
let hyprlandUnstable = final: prev: {
  hyprland = prev.unstable.hyprland;
};
in
{
  nixpkgs.overlays = [ hyprlandUnstable ];
}
