{ pkgs, userParams, ... }:

let
  steam-nvidia = pkgs.writeShellScriptBin "steam-nvidia" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only

    ## experimental
    ## maybe helps with stutters
    # export __GL_GSYNC_ALLOWED=0
    # export __GL_VRR_ALLOWED=0

    # UI scaling
    export GDK_SCALE=2

    # Proton support
    STEAM_EXTRA_COMPAT_TOOLS_PATHS=~/.steam/root/compatibilitytools.d

    steam $@
  '';
in
{
  programs.steam.enable = true;

  ## Make Steam use nvidia-offload
  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    home.activation.steam = lib.hm.dag.entryAfter [ "installPackages" ] ''
      ## See:
      ## https://nixos.wiki/wiki/Nvidia

      mkdir -p ~/.local/share/applications
      sed 's#^Exec=steam#Exec=${steam-nvidia}/bin/steam-nvidia#g' /run/current-system/sw/share/applications/steam.desktop > ~/.local/share/applications/steam.desktop
    '';
  };
}
