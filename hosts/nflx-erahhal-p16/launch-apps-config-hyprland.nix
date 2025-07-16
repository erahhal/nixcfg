{ userParams, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      misc = {
        # vrr = 0;
      };

      render = {
        direct_scanout = false;
        explicit_sync = true;
      };

      cursor = {
        no_hardware_cursors = true;
      };

      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"

        # "AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1"
        # "AQ_FORCE_LINEAR_BLIT,1"
        # "__GL_SYNC_TO_VBLANK,1"
        # "__GL_GSYNC_ALLOWED,0"
        # "__GL_VRR_ALLOWED,0"
        # "__GL_TRIPLE_BUFFER,1"

        # "__NV_PRIME_RENDER_OFFLOAD,1"
        # "__VK_LAYER_NV_optimus,NVIDIA_only"

        # "WLR_DRM_NO_ATOMIC,1"
        # "__VK_LAYER_NV_optimus,NVIDIA_only"
        # "NVD_BACKEND,direct"

        "STEAM_FORCE_DESKTOPUI_SCALING,2.0"
      ];

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
        "eDP-1,3840x2160@60,0x0,2.133333"
        "desc:LG Electronics 16MQ70 20NKZ005285,2560x1600@60,1599x0,1.6"
        "desc:LG Electronics LG Ultra HD 0x00043EAD,3840x2160@60,0x0,1.5"
        "desc:LG Electronics L33HD334K 0x00020F5B,3840x2160@60,2560x0,1.5"
        "desc:Lenovo Group Limited P40w-20 V90DFGMV,5120x2160@74.978996,0x0,1.333333"
        # "desc:Lenovo Group Limited P40w-20 V90DFGMV,5120x2160@60,0x0,1.0"
      ];

      workspace = [
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 1"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 4"
        "desc:LG Electronics LG Ultra HD 0x00043EAD, 5"
        "desc:LG Electronics LG HDR 4K 0x00020F5B, 2"
        "desc:LG Electronics LG HDR 4K 0x00020F5B, 7"
      ];

      windowrulev2 = [
        "workspace 2, silent, class:^(kitty)$"
        "workspace 2, silent, class:^(foot)$"
        "workspace 3, silent, class:^(Slack)$"
        "workspace 4, silent, title:^(Spotify Premium)$"
        "workspace 4, silent, class:^(brave-browser)$"
        "workspace 5, silent, class:^(firefox)$"
        "workspace 5, silent, class:^(floorp)$"
        "workspace 5, silent, class:^(librewolf)$"
        "workspace 6, class:^(signal)$"
        "workspace 6, class:^(org.telegram.desktop)$"
        "workspace 6, class:^(whatsapp-for-linux)$"
        "workspace 7, class:^(discord)$"
        "workspace 7, class:^(Element)$"
        "workspace 1, silent, class:^(chromium-browser)$"
      ];

      exec-once = [
        "[workspace 2 silent] ${userParams.tty} tmux a -dt code"
        "[workspace 3 silent] slack"
        "[workspace 4 silent] spotify"
        "[workspace 4 silent] brave"
        "[workspace 5 silent] firefox"
        "[workspace 6 silent] signal-desktop"
        # "[workspace 6 silent] telegram-desktop"
        # "[workspace 6 silent] whatsapp-for-linux"
        "[workspace 7 silent] discord"
        # "[workspace 7 silent] element-desktop"
        "[workspace 1 silent] chromium"
      ];
    };
  };
}
