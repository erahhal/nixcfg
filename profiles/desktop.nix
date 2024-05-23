{ lib, pkgs, userParams, ...}:
let
  # This is needed to set the cursor for SDDM
  default-mouse-cursor = pkgs.stdenv.mkDerivation rec {
    pname = "default-mouse-cursor";
    version = "0.1";

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      cat <<EOT >> index.theme
      [Icon Theme]
      Inherits=Bibata-Modern-Classic
      EOT

      install -dm 0755 $out/share/icons/default
      install -D index.theme $out/share/icons/default/index.theme

      runHook postInstall
    '';

    meta = with lib; {
      description = "Set default icon";
      platforms = platforms.linux;
    };
  };
in
{
  imports =
    [
      ./xserver.nix
      ./sddm.nix
      ./lightdm.nix
      ./i3.nix
      ./wayland-window-manager.nix
      # ./plasma6.nix
      ./sway.nix
      ./hyprland.nix
      ./fonts.nix
    ];

  environment.systemPackages = with pkgs; [
    glxinfo
    inxi
    libcamera
    bibata-cursors

    default-mouse-cursor

    # inputs.nix-software-center.packages."${system}".nix-software-center
  ];
}
