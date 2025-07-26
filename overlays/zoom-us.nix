{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      zoom-us-scaled = prev.zoom-us.overrideAttrs (oldAttrs: {
        qtWrapperArgs = (oldAttrs.qtWrapperArgs or []) ++ [
          "--set" "QT_SCALE_FACTOR" "2"
        ];
        postFixup = (oldAttrs.postFixup or "") + ''
          wrapProgram $out/bin/zoom-us --unset XDG_SESSION_TYPE
        '';
        postInstall = (oldAttrs.postInstall or "") + ''
          wrapProgram $out/bin/zoom \
            --set QT_SCALE_FACTOR 2
        ];
        '';
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ prev.makeWrapper ];
      });
    })
  ];
}

