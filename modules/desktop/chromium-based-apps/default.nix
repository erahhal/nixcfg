{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.desktop.chromium-based-apps;
  usingIntel = config.hostParams.gpu.intel.enable;
  # Pin apps to the Intel iGPU on hybrid Intel+NVIDIA hosts. Must not apply on
  # AMD hosts: LIBVA_DRIVER_NAME=iHD breaks libva init there, which knocks out
  # VAAPI (e.g. OBS falls back to x264 software encoding and drops frames).
  forceIgpuFlags = lib.optionalString usingIntel (lib.concatStringsSep " " [
    "--set DRI_PRIME 0"
    "--set GBM_BACKEND mesa"
    "--set LIBVA_DRIVER_NAME iHD"
    "--set __GLX_VENDOR_LIBRARY_NAME mesa"
    "--unset __NV_PRIME_RENDER_OFFLOAD"
    "--unset __VK_LAYER_NV_optimus"
  ]);
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
        makeWrapper ${originalChromium}/bin/chromium $out/bin/chromium ${forceIgpuFlags}
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
        makeWrapper ${originalBrave}/bin/brave $out/bin/brave ${forceIgpuFlags}
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
        makeWrapper ${originalSlack}/bin/slack $out/bin/slack ${forceIgpuFlags} \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder,ScrollUnification,DropInputEventsWhilePaintHolding,ElasticOverscroll" \
          --add-flags "--disable-smooth-scrolling" \
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

    # symlinkJoin-wrap (not overrideAttrs) so the underlying prebuilt Electron
    # tarball stays cache-hit; only the tiny wrapper derivation builds locally.
    signal-desktop = let
      original = prev.signal-desktop;
    in prev.symlinkJoin {
      name = "signal-desktop-${original.version}";
      paths = [ original ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/signal-desktop
        makeWrapper ${original}/bin/signal-desktop $out/bin/signal-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--password-store=gnome-libsecret" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
          --add-flags "--disable-features=ScrollUnification"
      '';
      inherit (original) meta;
    };

    element-desktop = let
      original = prev.element-desktop;
    in prev.symlinkJoin {
      name = "element-desktop-${original.version}";
      paths = [ original ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/element-desktop
        makeWrapper ${original}/bin/element-desktop $out/bin/element-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
      inherit (original) meta;
    };

    spotify = let
      original = prev.spotify;
    in prev.symlinkJoin {
      name = "spotify-${original.version}";
      paths = [ original ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/spotify
        makeWrapper ${original}/bin/spotify $out/bin/spotify \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
          --add-flags "--disable-features=UseChromeOSDirectVideoDecoder,VaapiVideoDecoder,AcceleratedVideoDecodeLinuxGL"
      '';
      inherit (original) meta;
    };

    vesktop = let
      original = prev.vesktop;
    in prev.symlinkJoin {
      name = "vesktop-${original.version}";
      paths = [ original ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/vesktop
        makeWrapper ${original}/bin/vesktop $out/bin/vesktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
          ${if usingIntel then ''--add-flags "--disable-gpu-compositing"'' else ""}
      '';
      inherit (original) meta;
    };

    joplin-desktop = let
      original = prev.joplin-desktop;
    in prev.symlinkJoin {
      name = "joplin-desktop-${original.version}";
      paths = [ original ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/joplin-desktop
        makeWrapper ${original}/bin/joplin-desktop $out/bin/joplin-desktop \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
      inherit (original) meta;
    };

    obs-studio = let
      originalObs = prev.obs-studio;
    in prev.symlinkJoin {
      name = "obs-studio-${originalObs.version}";
      paths = [ originalObs ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/obs
        makeWrapper ${originalObs}/bin/obs $out/bin/obs ${forceIgpuFlags}
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
        for prefs in ~/.config/chromium/Default/Preferences; do
          if [ -e "$prefs" ]; then
            ${pkgs.gnused}/bin/sed -i 's/"custom_chrome_frame":true/"custom_chrome_frame":false/g' "$prefs"
            # Enable system theme following for live dark/light switching
            ${pkgs.python3}/bin/python3 -c "
import json
path = '$prefs'
with open(path) as f:
    d = json.load(f)
bt = d.setdefault('browser', {}).setdefault('theme', {})
bt['follows_system_colors'] = True
bt['color_scheme2'] = 0
et = d.setdefault('extensions', {}).setdefault('theme', {})
et.pop('id', None)
et.pop('pack', None)
with open(path, 'w') as f:
    json.dump(d, f)
" 2>/dev/null || true
          fi
        done
      '';
    };

    nixpkgs.overlays = [ chromium-overlays ];
  };
}
