{ pkgs, ... }:

let steam-nvidia = self: super: {
  steam = super.steam.overrideAttrs (old: {
    # add `makeWrapper` to existing dependencies
    buildInputs = (old.buildInputs or []) ++ [ pkgs.makeWrapper ];
    # wrap the binary in a script where the appropriate env var is set
    postInstall = old.postInstall or "" + ''
      wrapProgram "$out/bin/steam" \
        --set __NV_PRIME_RENDER_OFFLOAD 1 \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
        --set __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set __VK_LAYER_NV_optimus NVIDIA_only \
        --set STEAM_EXTRA_COMPAT_TOOLS_PATHS ~/.steam/root/compatibilitytools.d
    '';
  });
};
in
{
  nixpkgs.overlays = [ steam-nvidia ];
}
