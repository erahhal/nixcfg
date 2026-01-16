{ config, pkgs, userParams, ... }:
let
  usingIntel = config.hostParams.gpu.intel.enable;
  defaultIntel = config.hostParams.gpu.intel.defaultWindowManagerGpu;

  chromium-intel-script = pkgs.writeShellScriptBin "chromium-intel" ''
    # Ensure flatpak is available
    if ! command -v flatpak &> /dev/null; then
      echo "Error: flatpak is not installed"
      echo "Add 'services.flatpak.enable = true;' to your configuration.nix"
      exit 1
    fi

    # Check if Chromium flatpak is installed
    if ! flatpak list --app | grep -q "org.chromium.Chromium"; then
      echo "Chromium flatpak is not installed."
      echo "Installing now..."
      flatpak install -y flathub org.chromium.Chromium
    fi

    # Launch Chromium with Intel GPU forced
    exec flatpak run \
      --filesystem=~/.config/chromium:rw \
      --filesystem=xdg-run/pipewire-0:ro \
      --socket=wayland \
      --socket=pulseaudio \
      --share=ipc \
      --device=dri \
      --env=DRI_PRIME=0 \
      --env=__GLX_VENDOR_LIBRARY_NAME=mesa \
      --env=LIBVA_DRIVER_NAME=iHD \
      org.chromium.Chromium \
        --user-data-dir="$HOME/.config/chromium" \
        --enable-features=WebRTCPipeWireCapturer \
        --ozone-platform=wayland \
        "$@"
  '';

  chromium-intel-desktop = pkgs.makeDesktopItem {
    name = "chromium-intel";
    desktopName = "Chromium (Intel GPU)";
    exec = "${chromium-intel-script}/bin/chromium-intel %U";
    icon = "org.chromium.Chromium";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  chromium-native-desktop = pkgs.makeDesktopItem {
    name = "chromium-native";
    desktopName = "Chromium (Native)";
    exec = "chromium-native %U";
    icon = "org.chromium.Chromium";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  chromium-intel = pkgs.symlinkJoin {
    name = "chromium";
    paths = [ chromium-intel-script chromium-intel-desktop chromium-native-desktop ];
  };

  chromiumWaylandIme = final: prev: {
    chromium = (prev.chromium.override {
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
    }).overrideAttrs (oldAttrs: {
      # Force Intel GPU for screen sharing compatibility with Niri (which renders on Intel)
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/chromium \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa
      '';
    });

    brave = (prev.brave.override {
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
    }).overrideAttrs (oldAttrs: {
      # Force Intel GPU for screen sharing compatibility with Niri (which renders on Intel)
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/brave \
          --unset __NV_PRIME_RENDER_OFFLOAD \
          --unset __VK_LAYER_NV_optimus \
          --set DRI_PRIME 0 \
          --set GBM_BACKEND mesa \
          --set LIBVA_DRIVER_NAME iHD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa
      '';
    });

    slack = prev.slack.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/slack \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder" \
          --add-flags "--enable-features=WebRTCPipeWireCapturer" \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WebRTCPipeWireCapturer,VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo" \
          --add-flags "--enable-gpu-rasterization" \
          --add-flags "--enable-oop-rasterization" \
          --add-flags "--ignore-gpu-blocklist" \
          --add-flags "--enable-zero-copy"
      '';
    });

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
    ## Whatsapp works out of the box

    ## Telegram works out of the box
  };
  default-chrome = if usingIntel then (if defaultIntel then "chromium-native" else "chromium-intel") else "chromium-native";
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

  nixpkgs.overlays = [ chromiumWaylandIme ];

  environment.systemPackages = [
    chromium-intel
    (pkgs.writeShellScriptBin "chromium" default-chrome)
    (pkgs.writeShellScriptBin "chromium-native" ''
      # Force Intel GPU for screen sharing compatibility with Niri (which renders on Intel)
      export DRI_PRIME=0
      export GBM_BACKEND=mesa
      export LIBVA_DRIVER_NAME=iHD
      export __GLX_VENDOR_LIBRARY_NAME=mesa
      unset __NV_PRIME_RENDER_OFFLOAD
      unset __VK_LAYER_NV_optimus
      exec ${pkgs.chromium}/bin/chromium "$@"
    '')
  ];
}
