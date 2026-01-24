{ config, userParams, ... }:
let
  usingIntel = config.hostParams.gpu.intel.enable;
  chromium-overlays = final: prev: {
    chromium = let
      originalChromium = prev.chromium.override {
        commandLineArgs = [
          "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
          "--enable-wayland-ime"
          "--password-store=basic" # Don't show kwallet login at start
          "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
          "--ozone-platform=wayland"
          "--enable-features=WebRTCPipeWireCapturer,VaapiVideoEncoder,VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo"
          "--enable-gpu-rasterization"
          "--enable-oop-rasterization"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
        ];
      };
    in (prev.symlinkJoin {
      name = "chromium-${originalChromium.version}";
      paths = [ originalChromium ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        # Remove symlinked wrapper and create new one with Intel GPU env vars
        # (needed for screen sharing compatibility with Niri which renders on Intel)
        rm $out/bin/chromium $out/bin/chromium-browser
        makeWrapper ${originalChromium}/bin/chromium $out/bin/chromium \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus
        ln -s $out/bin/chromium $out/bin/chromium-browser
      '';
      passthru = originalChromium.passthru // {
        inherit (originalChromium) sandbox;
      };
      inherit (originalChromium) meta;
    }) // {
      # Preserve override for packages like electron that need to build their own chromium
      inherit (prev.chromium) override;
    };

    brave = prev.brave.override {
      commandLineArgs = [
        "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
        "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
        "--ozone-platform=wayland"
        "--enable-features=WebRTCPipeWireCapturer,VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo"
        "--enable-gpu-rasterization"
        "--enable-oop-rasterization"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    };

    # Slack wrapped to use Intel GPU (for screen sharing compatibility with Niri)
    # Uses single wrapper with both env vars and flags to avoid nested wrapper issues
    slack = let
      originalSlack = prev.slack;
    in prev.symlinkJoin {
      name = "slack-${originalSlack.version}";
      paths = [ originalSlack ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/slack
        makeWrapper ${originalSlack}/bin/slack $out/bin/slack \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa \
          --set GTK_USE_PORTAL 1 \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WebRTCPipeWireCapturer,VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo" \
          --add-flags "--enable-gpu-rasterization" \
          --add-flags "--enable-oop-rasterization" \
          --add-flags "--ignore-gpu-blocklist" \
          --add-flags "--enable-zero-copy"
      '';
      inherit (originalSlack) meta;
    };

    signal-desktop-bin = prev.signal-desktop-bin.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/signal-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--password-store=gnome-libsecret" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
    });

    element-desktop = prev.element-desktop.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/element-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
    });

    spotify = prev.spotify.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/spotify \
          --add-flags "--enable-wayland-ime"
      '';
    });

    vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/vesktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
          ${if usingIntel then ''--add-flags "--disable-gpu-compositing"'' else ""}
      '';
    });

    # discord = prev.discord.overrideAttrs (oldAttrs: {
    #   buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    #   postInstall = oldAttrs.postInstall or "" + ''
    #     wrapProgramShell $out/opt/Discord/Discord \
    #         --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
    #   '';
    # });

    joplin-desktop = prev.joplin-desktop.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/joplin-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
    });

    # OBS Studio wrapped to use Intel GPU (for screen recording compatibility with Niri)
    obs-studio = let
      originalObs = prev.obs-studio;
    in prev.symlinkJoin {
      name = "obs-studio-${originalObs.version}";
      paths = [ originalObs ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/obs
        makeWrapper ${originalObs}/bin/obs $out/bin/obs \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus
      '';
      inherit (originalObs) meta;
    };

    ## Whatsapp works out of the box

    ## Telegram works out of the box
  };
in
{
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home.activation.chromium = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Get to this setting by clicking the tab strip then checking "Use system title bar and borders"
      if [ -e ~/.config/chromium/Default/Preferences ]; then
        ${pkgs.gnused}/bin/sed -i 's/"custom_chrome_frame":true/"custom_chrome_frame":false/g' ~/.config/chromium/Default/Preferences
      fi
    '';
  };

  nixpkgs.overlays = [ chromium-overlays ];
}
