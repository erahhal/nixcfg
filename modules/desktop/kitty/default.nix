{ osConfig, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    # Font handled by Stylix
    settings = {
      enable_audio_bell = false;
      copy_on_select = "yes";
    };
    extraConfig = ''
      linux_display_server  wayland
    '';
  };
}
