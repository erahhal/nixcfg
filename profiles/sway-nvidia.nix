args@{ lib, hostParams, userParams, ... }:

{
  config = if hostParams.defaultSession == "sway" then {
    home-manager.users.${userParams.username} = { pkgs, ... }: {
      home.sessionVariables = {
        GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        ## Overrides
        # GBM_BACKEND = lib.mkForce "nvidia";
        GBM_BACKEND = lib.mkForce "nvidia-drm";
        QT_AUTO_SCREEN_SCALE_FACTOR = lib.mkForce "1";
        QT_QPA_PLATFORM = lib.mkForce "wayland";

        # From: https://www.reddit.com/r/swaywm/comments/sphp7b/a_quick_look_to_sway_wm_with_nvidias_drivers/
        GL_GSYNC_ALLOWED = "0";
        __GL_VRR_ALLOWED = "0";
        WLR_DRM_NO_ATOMIC = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        GDK_BACKEND = "wayland";
        XDG_CURRENT_DESKTOP = "sway";
        WLR_NO_HARDWARE_CURSORS = "1";

        ## Sway doesn't load with this
        # WLR_RENDERER = "vulkan";
      };
    };
  } else {};
}