{ config, userParams, ... }:
let
  usingIntel = config.hostParams.gpu.intel.enable;
  chromium-overlays = final: prev: {
    chromium = let
      originalChromium = prev.chromium.override {
        commandLineArgs = [
          "--enable-wayland-ime"
          "--password-store=basic" # Don't show kwallet login at start
          "--ozone-platform=wayland"
          # Chrome 143+ enables HW video decode by default. Disable it to fix flickering
          # in video calls (Google Meet) on Niri. The ANGLE DMA-BUF rendering path is buggy.
          # See: https://github.com/basecamp/omarchy/issues/3891
          "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder,VaapiVideoDecoder,AcceleratedVideoDecodeLinuxGL"
          "--enable-features=WebRTCPipeWireCapturer,WaylandWindowDecorations,WaylandLinuxDrmSyncobj,UseOzonePlatform"
          "--enable-gpu-rasterization"
          "--enable-oop-rasterization"
          "--ignore-gpu-blocklist"
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

    brave = let
      originalBrave = prev.brave.override {
        commandLineArgs = [
          "--enable-wayland-ime"
          "--password-store=basic" # Don't show kwallet login at start
          "--ozone-platform=wayland"
          # Disable HW video decode to fix flickering in video calls on Niri.
          # The ANGLE DMA-BUF rendering path is buggy.
          # See: https://github.com/basecamp/omarchy/issues/3891
          "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder,VaapiVideoDecoder,AcceleratedVideoDecodeLinuxGL"
          "--enable-features=WebRTCPipeWireCapturer,WaylandWindowDecorations,WaylandLinuxDrmSyncobj,UseOzonePlatform"
          "--enable-gpu-rasterization"
          "--enable-oop-rasterization"
          "--ignore-gpu-blocklist"
        ];
      };
    in (prev.symlinkJoin {
      name = "brave-${originalBrave.version}";
      paths = [ originalBrave ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        # Remove symlinked wrapper and create new one with Intel GPU env vars
        # (needed for screen sharing compatibility with Niri which renders on Intel)
        rm $out/bin/brave
        makeWrapper ${originalBrave}/bin/brave $out/bin/brave \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus
      '';
      passthru = originalBrave.passthru;
      inherit (originalBrave) meta;
    });

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

        # Fix .desktop file to point to wrapped binary (for DMS launcher)
        rm -rf $out/share/applications
        mkdir -p $out/share/applications
        substitute ${originalSlack}/share/applications/slack.desktop $out/share/applications/slack.desktop \
          --replace-fail "${originalSlack}/bin/slack" "$out/bin/slack"
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

    ## Zoom seems to work out of the box now

    ## Zoom wrapped with 2x scaling for HiDPI displays
    # zoom-us = let
    #   originalZoom = prev.zoom-us;
    # in prev.symlinkJoin {
    #   name = "zoom-us-${originalZoom.version}";
    #   paths = [ originalZoom ];
    #   nativeBuildInputs = [ prev.makeWrapper ];
    #   postBuild = ''
    #     rm $out/bin/zoom $out/bin/zoom-us
    #     makeWrapper ${originalZoom}/bin/zoom $out/bin/zoom \
    #       --set QT_SCALE_FACTOR 2
    #     ln -s $out/bin/zoom $out/bin/zoom-us
    #   '';
    #   inherit (originalZoom) meta;
    # };

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
