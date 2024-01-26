args@{ lib, hostParams, userParams, ... }:

{
  home-manager.users.${userParams.username} = { pkgs, ... }: {
    home.sessionVariables = {

## Exact reference set of vars that has worked in the past:
##
#   __NV_PRIME_RENDER_OFFLOAD = "1";
#   __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
#   __VK_LAYER_NV_optimus = "NVIDIA_only";
#   LIBVA_DRIVER_NAME = "nvidia";
#   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#   GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
#   __GL_GSYNC_ALLOWED = "0";
#   __GL_VRR_ALLOWED = "0";
#   GBM_BACKEND = lib.mkForce "nvidia-drm";
#   WLR_NO_HARDWARE_CURSORS = "1";
#   WLR_DRM_NO_ATOMIC = "1";
#   QT_AUTO_SCREEN_SCALE_FACTOR = lib.mkForce "1";
#   QT_QPA_PLATFORM = lib.mkForce "wayland;xcb";
#   QT_QPA_PLATFORNTHEME = "qt5ct";
#   QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
#   GDK_BACKEND = "wayland,x11";

      # See: https://www.reddit.com/r/swaywm/comments/sphp7b/a_quick_look_to_sway_wm_with_nvidias_drivers/

      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      LIBVA_DRIVER_NAME = "nvidia";

      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";

      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";

      ## Overrides value in gfx-nvidia
      GBM_BACKEND = lib.mkForce "nvidia-drm";

      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_DRM_NO_ATOMIC = "1";

      QT_AUTO_SCREEN_SCALE_FACTOR = lib.mkForce "1";
      QT_QPA_PLATFORM = lib.mkForce "wayland;xcb";
      QT_QPA_PLATFORNTHEME = "qt5ct";

      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      GDK_BACKEND = "wayland,x11";

      #-------------------------------------------------
      # Unknown impact/use
      #-------------------------------------------------

      # CLUTTER_BACKEND = "wayland";
      # GBM_BACKEND = lib.mkForce "nvidia";

      #-------------------------------------------------
      # Broken
      #-------------------------------------------------

      ## Interferes with gamescope
      # SDL_VIDEODRIVER = "wayland";

      ## Sway doesn't load with this
      # WLR_RENDERER = "vulkan";

      ## Supposedly gets rid of flickering and weird transparency
      ## but can cause performance issues
      ## glxgears does not work with this
      ## steam setfaults
      # XWAYLAND_NO_GLAMOR = "1";
    };
  };
}
