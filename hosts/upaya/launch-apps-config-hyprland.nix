{ pkgs, lib, ... }:
{
  options = {
    launchAppsConfigHyprland = lib.mkOption {
      type = lib.types.lines;
      default = ''
        env = XDG_CURRENT_DESKTOP, hyprland
        env = LIBVA_DRIVER_NAME,nvidia
        env = XDG_SESSION_TYPE,wayland
        env = GBM_BACKEND,nvidia-drm
        env = __GLX_VENDOR_LIBRARY_NAME,nvidia
        env = WLR_NO_HARDWARE_CURSORS,1

        # These are set by kanshi, but need to be set here as well to get cursor size correct
        # Some mix of settings here + kanshi causes kanshi to fail with:
        # "failed to apply  configuration for profile 'desk-hyprland'"
        # It might be enabling VRR or inconsistent frequencies
        monitor = eDP-1,3840x2160@60,0x0,2.0
        monitor = desc:LG Electronics 16MQ70 20NKZ005285,2560x1600@60,1598x0,1.6
        monitor = desc:LG Electronics LG Ultra HD 0x00043EAD,3840x2160@60,0x0,1.5
        monitor = desc:LG Electronics LG HDR 4K 0x00020F5B,3840x2160@60,2560x0,1.5

        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 1
        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 4
        workspace = desc:LG Electronics LG Ultra HD 0x00043EAD, 5

        workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 2
        workspace = desc:LG Electronics LG HDR 4K 0x00020F5B, 7

        # workspace 1
        windowrule = workspace 1, silent, class:^(firefox)$
        exec-once = [workspace l silent] firefox

        # workspace 2
        windowrule = workspace 2, silent, class:^(kitty)$
        exec-once = [workspace 2 silent] kitty tmux a -dt code

        # workspace 4
        windowrule = workspace 4 silent, title:^(Spotify)$
        exec-once = [workspace 4 silent] spotify
        windowrule = workspace 4 silent, class:^(brave-browser)$
        exec-once = [workspace 4 silent] brave

        # workspace 6
        windowrule = workspace 6, class:^(signal)$
        exec-once = [workspace 6 silent] signal-desktop

        # workspace 7
        windowrule = workspace 7, class:^(discord)$
        exec-once = [workspace 7 silent] discord
      '';
    };
  };
}
