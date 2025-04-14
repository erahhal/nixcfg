{ config, userParams, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "_GLX_VENDOR_LIBRARY_NAME,nvidia"
        "STEAM_FORCE_DESKTOPUI_SCALING,3.0"

        "__GLX_VRM_DEVICES,nvidia"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"

        # "__NV_PRIME_RENDER_OFFLOAD,1"
        # "__VK_LAYER_NV_optimus,NVIDIA_only"
        # "GBM_BACKEND,nvidia-drm"
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

        "desc:LG Electronics LG TV SSCR2 0x01010101,preferred,0x0,3.0"
        "desc:Valve Corporation Index HMD 0x92B574CE,preferred,0x0,1.0"
      ];

      windowrulev2 = [
        "workspace 2, silent, class:^(kitty)$"
        "workspace 2, silent, class:^(foot)$"
        "workspace 3, silent, class:^(Slack)$"
        "workspace 4, silent, title:^(Spotify)$"
        "workspace 4, silent, class:^(brave-browser)$"
        # "workspace 5, silent, class:^(firefox)$"
        "workspace 6, class:^(signal)$"
        "workspace 6, class:^(org.telegram.desktop)$"
        "workspace 6, class:^(whatsapp-for-linux)$"
        "workspace 7, class:^(discord)$"
        "workspace 7, class:^(Element)$"
        "workspace 1, silent, class:^(chromium-browser)$"
      ];

      exec-once = [
        "openrgb --gui --startminimized -m direct -c 00FF66"
        "[workspace 2 silent] ${userParams.tty} tmux a -dt code"
        "[workspace 4 silent] spotify"
        "[workspace 4 silent] brave"
        # "[workspace 6 silent] signal-desktop"
        # "[workspace 6 silent] telegram-desktop"
        # "[workspace 6 silent] whatsapp-for-linux"
        # "[workspace 7 silent] discord"
        # "[workspace 7 silent] element-desktop"
        "[workspace 5 silent] firefox"
      ];
    };
  };
}
