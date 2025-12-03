final: prev: {
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      # Patch wlr.portal to include niri in UseIn field
      sed -i 's/UseIn=\(.*\);$/UseIn=\1;niri;/' $out/share/xdg-desktop-portal/portals/wlr.portal
    '';
  });
}
