{ pkgs, ... }:
let sway-with-input-methods = final: prev: {
  sway = prev.trunk.sway.override {
    sway-unwrapped = prev.trunk.sway-unwrapped.overrideAttrs (oa: {
      patches = (oa.patches or []) ++ [
        # Add input method support
        # https://github.com/swaywm/sway/pull/7226
        # Backported to 1.8.1 by AUR maintainers
        # https://aur.archlinux.org/packages/sway-im
        (pkgs.fetchurl {
          name = "0001-text_input-Implement-input-method-popups.patch";
          url = "https://aur.archlinux.org/cgit/aur.git/plain/0001-text_input-Implement-input-method-popups.patch?h=sway-im&id=9bba3fb267a088cca6fc59391ab45ebee654ada1";
          hash = "sha256-kqr9sHnk2wgfkC7so1y0EVVPd9kII3Oys/t2zmF2Q2c=";
        })
        (pkgs.fetchurl {
          name = "0002-backport-sway-im-to-v1.8.1.patch";
          url = "https://aur.archlinux.org/cgit/aur.git/plain/0002-backport-sway-im-to-v1.8.patch?h=sway-im&id=9bba3fb267a088cca6fc59391ab45ebee654ada1";
          hash = "sha256-MAKXW2StUX6ZqNtmwJhg5d39CiN4FMsi0m3H8uSp2B8=";
        })

        ## Github PR patch. Doesn't apply properly for some reason
        # (pkgs.fetchurl {
        #   name = "0003-input-method-popups.patch";
        #   url = "https://patch-diff.githubusercontent.com/raw/swaywm/sway/pull/7226.patch";
        #   hash = "sha256-KSSxMLeRJMpxTN3SQYAGtRGrpf/8Fxi4fKNej7pp1NA=";
        # })
      ];
    });
  };
};
in
{
  nixpkgs.overlays = [ sway-with-input-methods ];
}
