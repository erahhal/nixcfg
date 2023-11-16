# From: https://aur.archlinux.org/packages/wlroots-nvidia
# Need to update the patches from AUR by adding /a and /b to filenames

{ ... }:
let sway-with-nvidia-patches = final: prev: {
  sway = prev.unstable.sway;
  wlroots_0_16 = prev.wlroots_0_16.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [
      ./sway-with-nvidia-patches/nvidia.patch ./sway-with-nvidia-patches/dmabuf-capture-example.patch
    ];
  });
};
in
{
  nixpkgs.overlays = [ sway-with-nvidia-patches ];
}
