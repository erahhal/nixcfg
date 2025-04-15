{ pkgs, ... }:
let
  # pkgs.symlinkJoin doesn't work, probably due to desktopfile pointing to the wrong binary

  # downside of overrideAttrs approach is that it rebuilds the package
  signalWayland = pkgs.unstable.signal-desktop-bin.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/signal-desktop \
        --add-flags "--ozone-platform-hint=auto"
    '';
  });
in
{
  home.packages = [
    ## Often crashes with Sway.  Try again later
    ## See: https://github.com/signalapp/Signal-Desktop/issues/6247

    # signalWayland

    pkgs.unstable.signal-desktop-bin
  ];
}
