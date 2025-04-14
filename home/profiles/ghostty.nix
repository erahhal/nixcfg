{ hostParams, userParams, ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    settings = {
      theme = "tokyonight_night";
      font-family = "DejaVu Sans Mono";
      font-size = toString hostParams.ttyFontSize;
      link-url = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = false;
      window-vsync = false;
    };
  };
}
