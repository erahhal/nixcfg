{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      igv = prev.igv.overrideAttrs (oldAttrs: {
        installPhase = (oldAttrs.installPhase or "") + ''
          ## Double UI scaling, halve native file dialog scaling
          wrapProgram $out/bin/igv \
            --set GDK_SCALE 2 \
            --set GDK_DPI_SCALE 0.5
        '';
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ prev.makeWrapper ];
      });
    })
  ];
}

