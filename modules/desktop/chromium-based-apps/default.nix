{ config, lib, pkgs, userParams, ... }:
let
  cfg = config.nixcfg.desktop.chromium-based-apps;
  usingIntel = config.hostParams.gpu.intel.enable;
  chromium-overlays = final: prev: {
    chromium = let
      originalChromium = prev.chromium.override {
        commandLineArgs = [
          "--enable-wayland-ime"
          "--password-store=basic"
          "--ozone-platform=wayland"
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
      inherit (prev.chromium) override;
    };

    brave = let
      originalBrave = prev.brave.override {
        commandLineArgs = [
          "--enable-wayland-ime"
          "--password-store=basic"
          "--ozone-platform=wayland"
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

        rm -rf $out/share/applications
        mkdir -p $out/share/applications
        substitute ${originalSlack}/share/applications/slack.desktop $out/share/applications/slack.desktop \
          --replace-fail "${originalSlack}/bin/slack" "$out/bin/slack"
      '';
      inherit (originalSlack) meta;
    };

    signal-desktop = prev.signal-desktop.overrideAttrs (oldAttrs: {
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

    joplin-desktop = prev.joplin-desktop.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/joplin-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
    });

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
  };
in {
  options.nixcfg.desktop.chromium-based-apps = {
    enable = lib.mkEnableOption "Chromium-based app overlays (Wayland, IME, GPU)";
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
      home.activation.chromium = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -e ~/.config/chromium/Default/Preferences ]; then
          ${pkgs.gnused}/bin/sed -i 's/"custom_chrome_frame":true/"custom_chrome_frame":false/g' ~/.config/chromium/Default/Preferences
        fi
      '';
    };

    nixpkgs.overlays = [ chromium-overlays ];
  };
}
