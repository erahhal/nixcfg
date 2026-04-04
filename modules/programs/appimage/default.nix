{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.programs.appimage;
in {
  options.nixcfg.programs.appimage = {
    enable = lib.mkEnableOption "AppImage support via binfmt";
  };
  config = lib.mkIf cfg.enable {
    # "natively" run appimages
    # https://nixos.wiki/wiki/Appimage
    # Unfortunately, causes full rebuild of many packages
    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
  };
}
