{ config, pkgs, ... }:
let
  chromiumWaylandIme = final: prev: {
    chromium = prev.chromium.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
      ];
    };

    brave = prev.brave.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
      ];
    };

    slack = prev.slack.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        # wrapProgram $out/bin/slack \
        #   --add-flags "--enable-wayland-ime" \
        #   --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
        wrapProgram $out/bin/slack \
          --add-flags "--enable-wayland-ime"
      '';
    });

    signal-desktop-bin = prev.signal-desktop-bin.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/signal-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
    });

    # element-desktop = prev.element-desktop.overrideAttrs (oldAttrs: {
    #   postFixup = oldAttrs.postFixup or "" + ''
    #     wrapProgram $out/bin/element-desktop \
    #       --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
    #   '';
    # });

    spotify = prev.spotify.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/spotify \
          --add-flags "--enable-wayland-ime"
      '';
    });

    # discord = prev.discord.overrideAttrs (oldAttrs: {
    #   buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    #   postInstall = oldAttrs.postInstall or "" + ''
    #     wrapProgramShell $out/opt/Discord/Discord \
    #         --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
    #   '';
    # });

    ## @TODO: Doesn't work
    joplin-desktop = prev.joplin-desktop.overrideAttrs (oldAttrs: {
      extraInstallCommands = oldAttrs.extraInstallCommands or "" + ''
        wrapProgram $out/bin/joplin-desktop \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
      '';
    });
    ## Whatsapp works out of the box

    ## Telegram works out of the box
  };
  chromium-x11-script = pkgs.writeShellScriptBin "chromium-x11-script" ''
    ${pkgs.chromium}/bin/chromium "$@"
  '';
  brave-x11-script = pkgs.writeShellScriptBin "brave-x11-script" ''
    ${pkgs.brave}/bin/brave "$@"
  '';
in
{
  nixpkgs.overlays = [ chromiumWaylandIme ];
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name ="chrome-x11";
      pname = "chrome-x11";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${chromium-x11-script}/bin/chromium-x11-script $out/bin/chromium-x11
        wrapProgram $out/bin/chromium-x11 \
          --add-flags "--ozone-platform=x11" \
          --add-flags "--force-device-scale-factor=1.5"
      '';
    })
    (pkgs.stdenv.mkDerivation {
      name ="brave-x11";
      pname = "brave-x11";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${brave-x11-script}/bin/brave-x11-script $out/bin/brave-x11
        wrapProgram $out/bin/brave-x11 \
          --add-flags "--ozone-platform=x11" \
          --add-flags "--force-device-scale-factor=1.5"
      '';
    })
    (pkgs.stdenv.mkDerivation {
      name ="chrome-2x";
      pname = "chrome-2x";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${chromium-x11-script}/bin/chromium-x11-script $out/bin/chromium-2x
        wrapProgram $out/bin/chromium-2x \
          --add-flags "--ozone-platform=x11" \
          --add-flags "--force-device-scale-factor=2.0"
      '';
    })
    (pkgs.stdenv.mkDerivation {
      name ="brave-2x";
      pname = "brave-2x";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${brave-x11-script}/bin/brave-x11-script $out/bin/brave-2x
        wrapProgram $out/bin/brave-2x \
          --add-flags "--ozone-platform=x11" \
          --add-flags "--force-device-scale-factor=2x"
      '';
    })
  ];
}
