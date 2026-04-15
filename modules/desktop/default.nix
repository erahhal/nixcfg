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
    ./sddm
  ];

  options.nixcfg.desktop.enable = lib.mkEnableOption "desktop environment";

  config = lib.mkIf cfg.enable {
    # Disable Stylix chromium theme — use GTK mode instead for live dark/light switching
    stylix.targets.chromium.enable = false;

    # Stylix theming — centralized color scheme
    stylix = {
      enable = true;
      image = config.hostParams.desktop.wallpaper;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

      # Pure black background for OLED battery savings
      override = {
        base00 = "000000";
      };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 16;
      };

      fonts = {
        monospace = { name = "DejaVu Sans Mono"; package = pkgs.dejavu_fonts; };
        sansSerif = { name = "DejaVu Sans"; package = pkgs.dejavu_fonts; };
        serif = { name = "DejaVu Serif"; package = pkgs.dejavu_fonts; };
        sizes = {
          terminal = lib.mkDefault (builtins.floor config.hostParams.desktop.ttyFontSize);
          applications = 11;
          desktop = 10;
          popups = 10;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      mesa-demos
      inxi
      libcamera
      bibata-cursors
      default-mouse-cursor
    ];
  };
}
