{ ... }:

let bambuStudioWayland = self: super: {
  bambu-studio = super.bambu-studio.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/bambu-studio \
        --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
    '';
  });
};
in
{
  nixpkgs.overlays = [ bambuStudioWayland ];
}
