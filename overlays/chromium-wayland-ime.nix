{ ... }:
let chromiumWaylandIme = final: prev: {
  chromium = prev.chromium.override {
    commandLineArgs = [
      "--enable-wayland-ime"
    ];
  };

  brave = prev.brave.override {
    commandLineArgs = [
      "--enable-wayland-ime"
    ];
  };

  slack = prev.slack.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/slack \
        --add-flags "--enable-wayland-ime"
    '';
  });

  signal-desktop = prev.signal-desktop.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/signal-desktop \
        --add-flags "--enable-wayland-ime"
    '';
  });

  element-desktop = prev.element-desktop.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/element-desktop \
        --add-flags "--enable-wayland-ime"
    '';
  });

  spotify = prev.spotify.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/spotify \
        --add-flags "--enable-wayland-ime"
    '';
  });

  discord = prev.discord.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/discord \
        --add-flags "--enable-wayland-ime"
    '';
  });

  ## Whatsapp works out of the box

  ## Telegram works out of the box
};
in
{
  nixpkgs.overlays = [ chromiumWaylandIme ];
}
