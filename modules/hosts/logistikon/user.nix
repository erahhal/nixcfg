{ config, pkgs, lib, hostParams, ... }:
let userParams = config.hostParams.user; in
{
  home-manager.users.${userParams.username} = {

    imports = [
      ../../services/protonmail-bridge
      ../../programs/thunderbird
      ./hyprland.nix
      ./niri.nix
      ../../programs/clonehero
      ../../programs/minecraft
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender
        chromium
        nicotine-plus

        jetbrains-toolbox
        ## These are installed by jetbrains-toolbox with a corporate license
        # jetbrains.datagrip
        # jetbrains.idea-ultimate

        # lutris
        postgresql
        # nodejs-16_x
        qbittorrent
        transmission_4-gtk

        # AI
        # streamlit

        # Games
        ## prismlauncher comes from ../../programs/minecraft, wrapped for PRIME
        ## offload. Listing it here as well would collide on bin/prismlauncher.

        ## unstable
        trunk.bitwig-studio

        ## arduino
        arduino
        arduino-ide
        # platformio
      ];
    };

    ## nvidiaOffload because DP-2 scans out on the AMD iGPU (71:00.0) while the
    ## RTX 5090 sits at 01:00.0 -- the same split documented at length in
    ## ./configuration.nix. Without it the game renders on the iGPU.
    ##
    ## The 5090 is shared with llama-swap: a resident model and a shader pack
    ## at high LOD distance will contend for VRAM, so stop the models before a
    ## serious session rather than expecting both to fit.
    nixcfg.programs.minecraft = {
      enable = true;
      nvidiaOffload = true;
    };
  };
}

