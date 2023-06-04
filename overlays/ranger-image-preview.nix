{ pkgs, ... }:

let ranger-image-preview = self: super: {
  ranger = super.ranger.overrideAttrs (old: {
    imagePreviewSupport = true;
  });
};
in
{
  nixpkgs.overlays = [ ranger-image-preview ];
}
