{ ... }:

let erahhalOverlay = self: super: {
  erahhal = super.erahhal or {} // {
    blender = super.blender.overrideAttrs (oldAttrs: {
      postInstall = super.lib.optionalString super.stdenv.isDarwin ''
        mkdir $out/Applications
        mv $out/Blender.app $out/Applications
      '' + ''
        buildPythonPath "$pythonPath"
        wrapProgram $blenderExecutable \
          --prefix PATH : $program_PATH \
          --prefix PYTHONPATH : "$program_PYTHONPATH" \
          --add-flags '--python-use-system-env' \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only \
      '';
    });
  };
};
in
{
  nixpkgs.overlays = [ erahhalOverlay ];
}
