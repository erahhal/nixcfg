{ ... }:

let
  waybar-hyprland = final: prev: {
    waybar = prev.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    });
  };
in
{
  nixpkgs.overlays = [ waybar-hyprland ];
}
