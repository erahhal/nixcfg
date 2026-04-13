# Package config: allowUnfree, unstable/trunk channels, overlays
{ config, inputs, system, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      packageOverrides = pkgs: {
        unstable = import inputs.nixpkgs-unstable {
          config = config.nixpkgs.config;
          inherit system;
        };
        trunk = import inputs.nixpkgs-trunk {
          config = config.nixpkgs.config;
          inherit system;
        };
        erahhal = import inputs.nixpkgs-erahhal {
          config = config.nixpkgs.config;
          inherit system;
        };
        bottles = pkgs.bottles.override {
          removeWarningPopup = true;
        };
      };
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      # Fix Flatpak 1.16.4 regression that breaks sub-sandboxing with --app-path=""
      # (flatpak/flatpak#6568, fixed by flatpak/flatpak#6569)
      # This causes steam-runtime-check-requirements to fail, preventing Steam from launching.
      # Remove this overlay once nixpkgs updates to a Flatpak version that includes the fix.
      flatpak = prev.flatpak.overrideAttrs (old: {
        patches = (old.patches or []) ++ [ ../../../overlays/flatpak-fix-subsandbox.patch ];
      });

      # Pin gamescope to 3.16.4 to avoid SDL backend swapchain crash at high resolutions
      # (ValveSoftware/gamescope#1857, scRGB regression in 3.16.5+)
      # Remove this overlay once the upstream fix lands.
      gamescope = prev.gamescope.overrideAttrs (old: rec {
        version = "3.16.4";
        src = prev.fetchFromGitHub {
          owner = "ValveSoftware";
          repo = "gamescope";
          tag = version;
          fetchSubmodules = true;
          hash = "sha256-2AxqvZA1eZaJFKMfRljCIcP0M2nMngw0FQiXsfBW7IA=";
        };
      });

      jetbrains-toolbox = prev.jetbrains-toolbox.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [ prev.makeWrapper ];
        postInstall = old.postInstall or "" + ''
          wrapProgram "$out/bin/jetbrains-toolbox" \
            --add-flags "--graphics-api software"
        '';
      });

      ranger = prev.ranger.overrideAttrs (old: {
        imagePreviewSupport = true;
      });

      weechat = prev.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with prev.weechatScripts; [];
        };
      };
    })
  ];
}
