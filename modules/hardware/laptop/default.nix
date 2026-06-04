{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.laptop;
in {
  options.nixcfg.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware support (Thunderbolt, Bluetooth, console)";
  };
  config = lib.mkIf cfg.enable {
    # Thunderbolt
    services.hardware.bolt.enable = true;

    # Bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # --------------------------------------------------------------------------------------
    # Console
    # --------------------------------------------------------------------------------------

    # Use maximum resolution in systemd-boot for hidpi
    boot.loader.systemd-boot.consoleMode = "max";

    console = {
      keyMap = "us";
      earlySetup = true;
      # font = "${pkgs.terminus_font}/share/consolefonts/ter-132b.psf.gz";
      font = "ter-powerline-v32b";
      # font = "latarcyrheb-sun32";
      packages = [
        pkgs.terminus_font
        pkgs.powerline-fonts
      ];

      colors = [
        "000000" #"1f1f1F"
        "d73737"
        "60ac39"
        "cfb017"
        "6684e1"
        "b854d4"
        "1fad83"
        "a6a28c"
        "7d7a68"
        "d73737"
        "60ac39"
        "cfb017"
        "6684e1"
        "b854d4"
        "1fad83"
        "fefbec"
      ];
    };

    ## after boot, use graphical console TTY that supports TrueType fonts and glyphs

    # Stylix's kmscon target still sets the now-removed
    # services.kmscon.{fonts,extraConfig} options, which hard-fails the build on
    # current nixpkgs. Disable it until Stylix migrates upstream — this only
    # drops the base16 console palette; re-enable when Stylix is fixed.
    stylix.targets.kmscon.enable = false;

    # font-name needs the font available system-wide (+ fontconfig, which the
    # desktop already enables). Replaces the removed services.kmscon.fonts.
    fonts.packages = [ pkgs.nerd-fonts.droid-sans-mono ];

    services.kmscon = {
      enable = true;
      useXkbConfig = true;
      # nixpkgs removed services.kmscon.{fonts,extraConfig} and renamed
      # hwRender/term → config.{hwaccel,term}. All kmscon.conf settings now live
      # under `config` (bool true → bare flag, else key=value).
      config = {
        hwaccel = true;
        term = "xterm-256color";
        font-name = "DejaVu Sans Mono";
        backspace-delete = true;
        use-original-mode = true;
      };
      extraOptions = "--font-size 19";
    };

    # kmscon aliases itself as autovt@.service, so it claims tty1 at boot. greetd
    # then takes tty1 over, but the kernel's active VT can migrate to tty2 (where
    # the second kmsconvt is running) and never switches back, leaving the greeter
    # session non-active on seat0 — so niri can't become DRM master and the
    # screen stays black. Keep kmscon off tty1 so greetd owns it from boot.
    systemd.services."kmsconvt@tty1".enable = false;
  };
}
