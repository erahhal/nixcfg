{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      blender-hip = prev.symlinkJoin {
        name = "blender";
        paths = [ prev.blender-hip ];
        buildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/blender \
            --set __NV_PRIME_RENDER_OFFLOAD "1" \
            --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER "NVIDIA-G0" \
            --set __GLX_VENDOR_LIBRARY_NAME "nvidia" \
            --set __VK_LAYER_NV_optimus "NVIDIA_only"
        '';
      };
    })
  ];
}
