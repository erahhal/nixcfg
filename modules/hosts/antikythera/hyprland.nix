{ userParams, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      animations = {
        animation = [
          "border, 1, 2, default"
          "fade, 1, 4, default"
          "windows, 1, 3, default, popin 80%"
          "workspaces, 1, 2, default, slide"
        ];
      };

      monitor = [
        ## These are set by kanshi, but need to be set here as well to get cursor size correct
        ## Some mix of settings here + kanshi causes kanshi to fail with:
        ## "failed to apply  configuration for profile 'desk-hyprland'"
        ## It might be enabling VRR or inconsistent frequencies

        # "eDP-1,disable"
        # "eDP-1,2880x1800@120,0x0,1.8"
        # "eDP-1,preferred,auto,1.8"
        # "desc:LG Electronics 16MQ70 20NKZ005285,2560x1600@60,1599x0,1.6"
        # "desc:LG Electronics LG Ultra HD 0x00043EAD,3840x2160@60,0x0,1.5"
        # "desc:LG Electronics LG HDR 4K 0x00020F5B,3840x2160@60,2560x0,1.5"
        "eDP-1,preferred,0x1440,1.8"
        "desc:LG Electronics LG Ultra HD 0x00043EAD,preferred,652x0,1.5"
        "desc:LG Electronics LG HDR 4K 0x00020F5B,preferred,3212x0,1.5"
        # "desc:Lenovo Group Limited P40w-20 V90DFGMV,5120x2160@74.978996,0x0,1.250000"
        "desc:Lenovo Group Limited P40w-20 V90DFGMV,5120x2160@60.000,0x0,1.333333" # Don't use 74.97899 rate as it requires negotation and sometimes hangs for 20 seconds before displaying anything
      ];

      workspace = [
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 1"
        "desc:LG Electronics LG HDR 4K 0x00020F5B, 2"
        "desc:LG Electronics LG HDR 4K 0x00020F5B, 3"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 4"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 5"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 6"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 7"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 8"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 9"
      ];

      windowrulev2 = [
        "workspace 2, silent, class:^(kitty)$"
        "workspace 2, silent, class:^(foot)$"
        "workspace 3, silent, class:^(Slack)$"
        "workspace 4, silent, title:^(Spotify)$"
        "workspace 4, silent, class:^(brave-browser)$"
        # "workspace 5, silent, class:^(firefox)$"
        # "workspace 5, silent, class:^(floorp)$"
        # "workspace 5, silent, class:^(librewolf)$"
        "workspace 6, class:^(signal)$"
        "workspace 6, class:^(org.telegram.desktop)$"
        "workspace 6, class:^(whatsapp-for-linux)$"
        "workspace 7, class:^(discord)$"
        "workspace 7, class:^(vesktop)$"
        "workspace 7, class:^(Element)$"
        "workspace 9, initialClass:^(@joplin/app-desktop)$"
        "workspace 9, class:^(@joplin/app-desktop)$"
        "workspace 9, initialTitle:^(Joplin)$"
        "workspace 9, title:^(Joplin)$"
        "workspace 1, silent, class:^(chromium-browser)$"
      ];

      exec-once = [
        "[workspace 2 silent] ${userParams.tty} tmux a -dt code"
        "[workspace 4 silent] spotify"
        "[workspace 4 silent] brave"
        "[workspace 6 silent] signal-desktop"
        "[workspace 6 silent] telegram-desktop"
        "[workspace 6 silent] whatsapp-for-linux"
        # "[workspace 7 silent] discord"
        "[workspace 7 silent] vesktop"
        "[workspace 7 silent] element-desktop"
        "[workspace 9 silent] joplin-desktop"
        "[workspace 5 silent] firefox"
      ];
    };
  };
}
