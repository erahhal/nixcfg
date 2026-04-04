{ pkgs, ... }:
let
  package = pkgs.zellij;
  src = pkgs.fetchFromGitHub {
    owner = "zellij-org";
    repo = "zellij";
    # rev = "v${package.version}";
    rev = "v0.40.1";
    sha256 = "0mvkx5d69v4046bi9jr35rd5f0kz4prf0g7ja9xyh1xllpg8giv1";
  };
in
{
  home.file.".config/zellij/themes" = {
    recursive = true;
    source = "${src}/zellij-utils/assets/themes";
  };
  programs.zellij = {
    enable = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  xdg.configFile."zellij/config.kdl".text = ''
    // theme "gruvbox-dark"
    theme "catpuccin"
    scroll_buffer_size 100000
    pane_frames false
    // default_layout "compact"

    keybinds {
      unbind "Ctrl g" "Ctrl p" "Ctrl s"
      shared {
        bind "Alt g" { SwitchToMode "locked"; }
        bind "Alt h" { SwitchToMode "move"; }
        bind "Alt p" { SwitchToMode "pane"; }
        bind "Alt s" { SwitchToMode "scroll"; }
        bind "Ctrl h" { MoveFocus "Left"; }
        bind "Ctrl j" { MoveFocus "Down"; }
        bind "Ctrl k" { MoveFocus "Up"; }
        bind "Ctrl l" { MoveFocus "Right"; }
      }
    }
  '';
}
