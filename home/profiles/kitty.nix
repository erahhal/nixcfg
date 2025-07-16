{ osConfig, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      # name = "Terminus (TTF)";
      # package = pkgs.terminus_font_ttf;
      name = "DejaVu Sans Mono";
      package = pkgs.dejavu_fonts;
      size = osConfig.hostParams.desktop.ttyFontSize;
    };
    settings = {
      enable_audio_bell = false;
      copy_on_select = "yes";
    };
    extraConfig = ''
      linux_display_server  wayland
    '';
  };
}
