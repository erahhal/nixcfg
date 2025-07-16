{ lib, pkgs, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
in
{
  nixpkgs.overlays = [
    (final: prev: {
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
    })
  ];

  home-manager.users.${userParams.username} = {
    imports = [
      ./launch-apps-config-hyprland.nix
      ## Needed to create .desktop entry which is currently broken
      ## Also used to register mime types
      ../../home/profiles/jetbrains-toolbox.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender
        chromium

        lutris
        mcreator
        postgresql
        # nodejs-16_x
        transmission_4-gtk

        # AI
        # streamlit
        # vespa-cli

        # Games
        prismlauncher

        ## unstable
        trunk.bitwig-studio

        ## arduino
        arduino
        arduino-ide
        # platformio
      ];
    };
  };
}
