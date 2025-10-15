{ config, pkgs, userParams, ... }:
let
  usingIntel = config.hostParams.gpu.intel.enable;

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
      --env=DRI_PRIME=0 \
      --env=__GLX_VENDOR_LIBRARY_NAME=mesa \
      --env=LIBVA_DRIVER_NAME=iHD \
      --device=dri \
      org.chromium.Chromium --user-data-dir="$HOME/.config/chromium" "$@"
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

  chromium-intel = pkgs.symlinkJoin {
    name = "chromium";
    paths = [ chromium-intel-script chromium-intel-desktop ];
  };

  chromiumWaylandIme = final: prev: {
    chromium = prev.chromium.override {
      commandLineArgs = [
        "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
        "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
        "--ozone-platform=wayland"
        "--enable-features=VaapiVideoEncoder,VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo"
        "--enable-gpu-rasterization"
        "--enable-oop-rasterization"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    };

    brave = prev.brave.override {
      commandLineArgs = [
        "--enable-features=WaylandWindowDecorations,WaylandLinuxDrmSyncobj"
        "--enable-wayland-ime"
        "--password-store=basic" # Don't show kwallet login at start
        "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
        "--ozone-platform=wayland"
        "--enable-features=VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo"
        "--enable-gpu-rasterization"
        "--enable-oop-rasterization"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    };

    slack = prev.slack.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall or "" + ''
        wrapProgram $out/bin/slack \
          --add-flags "--enable-wayland-ime" \
          --add-flags "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder" \
          --add-flags "--enable-features=WebRTCPipeWireCapturer" \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=VaapiVideoDecoder,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseOzonePlatform,UseMultiPlaneFormatForHardwareVideo" \
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

    vesktop = if usingIntel then (prev.vesktop.overrideAttrs (oldAttrs: {
      ## Vesktop (and Discord) on Wayland WMs that are running nvidia as the main GPU.
      ## This fixes it (with a acceptable performance hit)
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/vesktop \
          --add-flags "--disable-gpu-compositing"
      '';
    })) else prev.vesktop;

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
    (pkgs.writeShellScriptBin "chromium" "chromium-intel")
  ];
}
