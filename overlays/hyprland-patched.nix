{ inputs, pkgs, ... }:
let hyprland-patched = final: prev: {
  hyprland-patched = inputs.hyprland.packages.${pkgs.system}.hyprland.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      # ./hyprland.patch
      (pkgs.fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/hyprwm/Hyprland/pull/6136.patch";
        sha256 = "03ajcjb91g27i45wbms3zbaf09m8lh6yykqid5g7iicqjw4jknv7";
      })
    ];
  });
};
in
{
  nixpkgs.overlays = [ hyprland-patched ];
}
