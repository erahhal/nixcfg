{ lib, ... }:
{
  options = {
    launchAppsConfigHyprland = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # workspace 2
        windowrule = workspace 2, silent, class:^(kitty)$
        exec-once = [workspace 2 silent] kitty tmux a -dt code

        # workspace 3
        windowrule = workspace 3, silent, class:^(Slack)$
        exec-once = [workspace 3 silent] slack

        # workspace 4
        windowrule = workspace 4 silent, title:^(Spotify)$
        exec-once = [workspace 4 silent] spotify
        windowrule = workspace 4 silent, class:^(brave-browser)$
        exec-once = [workspace 4 silent] brave

        # workspace 5
        windowrule = workspace 5, silent, class:^(firefox)$
        exec-once = [workspace 5 silent] firefox

        # workspace 6
        windowrule = workspace 6, class:^(signal)$
        exec-once = [workspace 6 silent] signal-desktop
        windowrule = workspace 6, class:^(org.telegram.desktop)$
        exec-once = [workspace 6 silent] telegram-desktop

        # workspace 7
        windowrule = workspace 7, class:^(discord)$
        exec-once = [workspace 7 silent] discord
        windowrule = workspace 7, class:^(Element)$
        exec-once = [workspace 7 silent] element-desktop

        # workspace 1
        windowrule = workspace 1, silent, class:^(chromium-browser)$
        exec-once = [workspace 1 silent] chromium
      '';
    };
  };
}
