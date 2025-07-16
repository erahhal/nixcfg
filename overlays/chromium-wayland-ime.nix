{ pkgs, ... }:
let
  chromiumWaylandIme = final: prev: {
    chromium = prev.chromium.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
        "--ozone-platform=x11"
        "--force-device-scale-factor=1.5"
      ];
    };

    brave = prev.brave.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
        "--ozone-platform=x11"
        "--force-device-scale-factor=1.5"
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
  chromium-p16-script = pkgs.writeShellScriptBin "chromium-p16-script" ''
    ${pkgs.chromium}/bin/chromium "$@"
  '';
  brave-p16-script = pkgs.writeShellScriptBin "brave-p16-script" ''
    ${pkgs.brave}/bin/brave "$@"
  '';
in
{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name ="chrome-p16";
      pname = "chrome-p16";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${chromium-p16-script}/bin/chromium-p16-script $out/bin/chromium-p16
        wrapProgram $out/bin/chromium-p16 \
          --add-flags "--force-device-scale-factor=2.0"
      '';
    })
    (pkgs.stdenv.mkDerivation {
      name ="brave-p16";
      pname = "brave-p16";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${brave-p16-script}/bin/brave-p16-script $out/bin/brave-p16
        wrapProgram $out/bin/brave-p16 \
          --add-flags "--force-device-scale-factor=2.0"
      '';
    })
  ];
  nixpkgs.overlays = [ chromiumWaylandIme ];
}
