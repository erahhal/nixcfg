{  ... }:
let
  hyprland-patched = final: prev: {
    hyprland-patched = prev.hyprland.overrideAttrs (finalAttrs: oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = oldAttrs.pname;
        fetchSubmodules = true;
        # rev = "eea0a6a";
        # hash = "sha256-aaF2FYy152AvdYvqn7kj+VNgp07DF/p8cLmhXD68i3A=";
        rev = "c95845b1488b4bd63e901cbdc4cb68c27a45971b";
        hash = "sha256-1oVVblacE6uQztHTTPG6NoUzj5RErIRbmDoVNWnG6xg=";
      };
    });

    hyprcursor = prev.hyprcursor.overrideAttrs (finalAttrs: oldAttrs: {
      version = "57298fc4f13c807e50ada2c986a3114b7fc2e621";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprcursor";
        rev = "57298fc4f13c807e50ada2c986a3114b7fc2e621";
        hash = "sha256-FIN1wMoyePBTtibCbaeJaoKNLuAYIGwLCWAYC1DJanw=";
      };
    });

    hyprlang = prev.hyprlang.overrideAttrs (finalAttrs: oldAttrs: {
      version = "87d5d984109c839482b88b4795db073eb9ed446f";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprlang";
        rev = "87d5d984109c839482b88b4795db073eb9ed446f";
        hash = "sha256-+qLn4lsHU6iL3+HTo1gTQ1tWzet8K9h+IfVemzEQZj8=";
      };
    });

    hyprland-protocols = prev.hyprland-protocols.overrideAttrs (finalAttrs: oldAttrs: {
      version = "0c2ce70625cb30aef199cb388f99e19a61a6ce03";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprland-protocols";
        rev = "0c2ce70625cb30aef199cb388f99e19a61a6ce03";
        hash = "sha256-zOEwiWoXk3j3+EoF3ySUJmberFewWlagvewDRuWYAso=";
      };
    });

    hyprwayland-scanner = prev.hyprwayland-scanner.overrideAttrs (finalAttrs: oldAttrs: {
      version = "0.3.9";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprwayland-scanner";
        rev = "v0.3.9";
        hash = "sha256-hRE0+vPXQYB37nx07HQMnaCV5wJjShOeqRygw3Ga6WM=";
      };
    });

    xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (finalAttrs: oldAttrs: {
      version = "91e48d6acd8a5a611d26f925e51559ab743bc438";
      src = final.fetchFromGitHub {
        owner = "hyprwm";
        repo = "xdg-desktop-portal-hyprland";
        rev = "91e48d6acd8a5a611d26f925e51559ab743bc438";
        hash = "sha256-1u9Exrc7yx9qtES2brDh7/DDZ8w8ap1nboIOAtCgeuM=";
      };
    });
  };
in
{
  nixpkgs.overlays = [ hyprland-patched ];
}
