{ config, pkgs, ... }:
let
  chromiumWaylandIme = final: prev: {
    chromium = prev.chromium.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
      ] ++ (if config.hostParams.gpu.nvidia.enable then [
        "--ozone-platform=x11"
        "--force-device-scale-factor=1.5"
      ] else []);
    };

    brave = prev.brave.override {
      commandLineArgs = [
        # "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
      ] ++ (if config.hostParams.gpu.nvidia.enable then [
        "--ozone-platform=x11"
        "--force-device-scale-factor=1.5"
      ] else []);
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
in
{
  nixpkgs.overlays = [ chromiumWaylandIme ];
}
