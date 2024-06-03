{ inputs, pkgs, ... }:
let
  # hyprland-patched = final: prev: {
  #   hyprland-patched = inputs.hyprland.packages.${pkgs.system}.hyprland.overrideAttrs (old: {
  #     patches = (old.patches or []) ++ [
  #       # ./hyprland.patch
  #       (pkgs.fetchpatch {
  #         url = "https://patch-diff.githubusercontent.com/raw/hyprwm/Hyprland/pull/6136.patch";
  #         sha256 = "03ajcjb91g27i45wbms3zbaf09m8lh6yykqid5g7iicqjw4jknv7";
  #       })
  #     ];
  #   });
  # };
  hyprland-patched = final: prev: {
    hyprland-patched = prev.trunk.hyprland.overrideAttrs (prev: rec {
      version = "unstable";
      src = final.fetchFromGitHub {
        owner = "levnikmyskin";
        repo = "hyprland";
        fetchSubmodules = true;
        # rev = "2e74d4e4316fa251e04742ffe2fe2def3a54134b";
        # hash = "sha256-19tEW0II2ExxBQbfDGg6FL2lAdKzBC4AWADAK4zWyX8=";
        rev = "2ad003810abacb30fa943aaac5ff793f36562f2a";
        hash = "sha256-T3s66G3GMggN0v7A8yzxi+2iqPzPaUIm76GFqDUQanQ=";
      };
    });

    trunk.hyprwayland-scanner = prev.trunk.hyprwayland-scanner.overrideAttrs (prev: rec {
      version = "0.3.8";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprwayland-scanner";
        rev = "v0.3.8";
        hash = "sha256-/DwglRvj4XF4ECdNtrCIbthleszAZBwOiXG5A6r0K/c=";
      };
    });
  };
in
{
  nixpkgs.overlays = [ hyprland-patched ];
}
