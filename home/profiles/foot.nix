{ hostParams, userParams, ... }:
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        shell = userParams.shell;
        term = "xterm-256color";
        font = "DejaVu Sans Mono:size=" + toString hostParams.ttyFontSize;
        dpi-aware = "no";
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
