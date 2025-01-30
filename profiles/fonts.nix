{ config, pkgs, lib, ... }:
{
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    corefonts
    fira-code fira-code-symbols
    terminus_font
    jetbrains-mono
    powerline-fonts
    gelasio
    iosevka
    noto-fonts noto-fonts-cjk-sans noto-fonts-emoji
    source-code-pro
    ttf_bitstream_vera
    terminus_font_ttf
  ]
  ++
  ## Install all nerdfonts
  builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
