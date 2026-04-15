{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    settings = {
      # Theme and fonts handled by Stylix
      link-url = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = false;
      window-vsync = false;
    };
  };
}
