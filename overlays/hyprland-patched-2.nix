{  ... }:
let
  hyprland-patched = final: prev: {
    hyprland-patched = prev.hyprland.overrideAttrs (finalAttrs: oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = oldAttrs.pname;
        fetchSubmodules = true;
        rev = "eea0a6a";
        hash = "sha256-aaF2FYy152AvdYvqn7kj+VNgp07DF/p8cLmhXD68i3A=";
        # rev = "098ac91";
        # hash = "sha256-ObX7qHLYwCDrKVi6Log7Uh3powuyR4lL/4txOiENpgI=";
      };
    });

    hyprwayland-scanner = prev.hyprwayland-scanner.overrideAttrs (finalAttrs: oldAttrs: {
      version = "0.3.8";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprwayland-scanner";
        # rev = "v0.3.8";
        # hash = "sha256-/DwglRvj4XF4ECdNtrCIbthleszAZBwOiXG5A6r0K/c=";
        rev = "v0.3.9";
        hash = "sha256-hRE0+vPXQYB37nx07HQMnaCV5wJjShOeqRygw3Ga6WM=";
      };
    });
  };
in
{
  nixpkgs.overlays = [ hyprland-patched ];
}
