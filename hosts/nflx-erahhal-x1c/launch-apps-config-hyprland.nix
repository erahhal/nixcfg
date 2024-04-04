{ lib, ... }:
{
  options = {
    launchAppsConfigHyprland = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # These are set by kanshi, but need to be set here as well to get cursor size correct
        monitor = eDP-1,2880x1800@90.000999,0x0,1.8,vrr,1
        monitor = desc:LG Electronics 16MQ70 20NKZ005285,2560x1600@60,1598x0,1.6,vrr,1
        monitor = desc:LG Electronics LG Ultra HD 0x00043EAD,3840x2160@60,1920x0,1.5,vrr,1
        monitor = desc:LG Electronics LG HDR 4K 0x00020F5B,3840x2160@60,4480x0,1.5,vrr,1

        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 1
        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 4
        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 5

        workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 2
        workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 7

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
