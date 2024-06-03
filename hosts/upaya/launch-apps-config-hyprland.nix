{ lib, ... }:
{

  wayland.windowManager.hyprland = {
    settings = {
      animations = {
        enabled = 0;
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

        # "eDP-1,3840x2160@60,0x0,2.0"
        # "eDP-1,disable"
        "desc:LG Electronics 16MQ70 20NKZ005285,2560x1600@60,1599x0,1.6"
        "desc:LG Electronics LG Ultra HD 0x00043EAD,3840x2160@60,0x0,1.5"
        "desc:LG Electronics LG HDR 4K 0x00020F5B,3840x2160@60,2560x0,1.5"
      ];

      ## Environemtn vars
      env = [
        "XDG_CURRENT_DESKTOP, hyprland"
        # "LIBVA_DRIVER_NAME,nvidia"
        "LIBVA_DRIVER_NAME,vdpau"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      windowrulev2 = [
        ## Perf
        "noblur, class:(.*)$"
        "forcergbx, class:(.*)$"

        "workspace 1, silent, class:^(firefox)$"
        "workspace 2, silent, class:^(kitty)$"
        "workspace 4, silent, title:^(Spotify)$"
        "workspace 4, silent, class:^(brave-browser)$"
        "workspace 6, class:^(signal)$"
        "workspace 6, class:^(org.telegram.desktop)$"
        "workspace 7, class:^(discord)$"
        "workspace 7, class:^(Element)$"
      ];

      exec-once = [
        "[workspace l silent] firefox"
        "[workspace 2 silent] kitty tmux a -dt code"
        "[workspace 4 silent] spotify"
        "[workspace 4 silent] brave"
        "[workspace 6 silent] signal-desktop"
        "[workspace 6 silent] telegram-desktop"
        "[workspace 7 silent] discord"
        "[workspace 7 silent] element-desktop"
      ];
    };

    extraConfig = lib.mkAfter ''
    '';
  };
}
