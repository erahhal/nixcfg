{ pkgs, ... }:
let
  # pkgs.symlinkJoin doesn't work, probably due to desktopfile pointing to the wrong binary

  # downside of overrideAttrs approach is that it rebuilds the package
  signalWayland = pkgs.signal-desktop.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/signal-desktop \
        --add-flags "--ozone-platform-hint=auto"
    '';
  });
in
{
  home.packages = [
    signalWayland
  ];
}
