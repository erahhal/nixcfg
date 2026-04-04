{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.desktop;

  default-mouse-cursor = pkgs.stdenv.mkDerivation {
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
in {
  # Sub-profiles are always imported (they have their own mkIf guards via hostParams)
  imports = [
    ../base-desktop
    ./wayland-window-manager
    ./plasma
    ./spacenavd
    ./i2c
    ./niri
    ./dms-shell
    ./sddm
  ];

  options.nixcfg.desktop.enable = lib.mkEnableOption "desktop environment";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mesa-demos
      inxi
      libcamera
      bibata-cursors
      default-mouse-cursor
    ];
  };
}
