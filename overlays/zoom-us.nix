{ lib, ... }:
  let zoom-us-scaled = self: super: {
    zoom-us = super.zoom-us.overrideAttrs (old: rec {
      ## This is a bad hack - it's fragile and expects the following
      ## strings in the original package derivation to not change.
      postFixup = lib.replaceStrings
        ["--unset QT_SCREEN_SCALE_FACTORS \\"]
        ["--unset QT_SCREEN_SCALE_FACTORS \\\n        --set QT_SCALE_FACTOR 1.5 \\"]
        old.postFixup;

      ## This doesn't work as the builder throws an error:
      ## "Cannot wrap zoom because it is not an executable file"
      # postInstall = old.postInstall or "" + ''
      #   wrapProgram $out/bin/zoom --set QT_SCALE_FACTOR 1.5
      # '';
    });
  };
in
{
  nixpkgs.overlays = [ zoom-us-scaled ];
}

