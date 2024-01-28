{ pkgs, hostParams, userParams, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "xterm-256color";
      };
      bell = {
        animation = "EaseOutExpo";
        duration = 5;
      };
      font = {
        normal = {
          family = "DejaVu Sans Mono";
          # style = "Medium";
        };
        size = hostParams.ttyFontSize;
      };
      hints.enabled = [
        {
          regex = ''(mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\u0000-\u001F\u007F-\u009F<>"\\s{-}\\^⟨⟩`]+'';
          command = "${pkgs.mimeo}/bin/mimeo";
          post_processing = true;
          mouse.enabled = true;
        }
      ];
      selection.save_to_clipboard = true;
      shell.program = userParams.shell;
      # "${pkgs.zsh}/bin/zsh";
      window = {
        decorations = "full";
        # opacity = 0.85;
        padding = {
          x = 5;
          y = 5;
        };
      };
    };
  };
}
