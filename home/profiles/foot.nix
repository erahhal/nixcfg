{ osConfig, userParams, ... }:
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        shell = userParams.shell;
        term = "xterm-256color";
        dpi-aware = "no";
        font = "DejaVu Sans Mono:size=" + toString osConfig.hostParams.desktop.ttyFontSize;
        # line-height = hostParams.ttyLineHeight;
        # font-bold = "";
        # font-italic = "";
        # font-bold-italic = "";
        # font-size-adjustment = 0.5;
        # letter-spacing = 0;
        # horizontal-letter-offset = 0;
        # vertical-letter-offset = 0;

        ## Attept to get rid of flickering next to waybar in hyprland
        ## BUT DOES NOT WORK
        resize-by-cells = "no";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      colors = {
        alpha = 1.0;
      };
    };
  };
}
