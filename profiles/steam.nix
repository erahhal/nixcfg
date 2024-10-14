{ pkgs, userParams, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession = {
      enable = true;
      ## Run wayland at native resolution
      args = [
        ''-W $(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .width")''
        ''-w $(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .width")''
        ''-H $(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .height")''
        ''-h $(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .height")''

        ## Full screen
        ''--fullscreen''
        ''--borderless''

        ''--backend sdl''
        # ''--backend wayland''

        ## Without it, the mouse won't move, or will be bound by window
        ## @TODO: Doesn't seem to work
        ''--force-grab-cursor''
        ## Scale cursor properly when --force-grab-cursor used
        ''--cursor-scale-height $(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .height")''

        ## Game framerate
        # ''-r 60''

        ''--adaptive-sync''

        ## Allow wayland apps/games to run
        # ''--expose-wayland''

      ];
    };
  };

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    protonup
    steam-tui
    steamcmd
  ];

  home-manager.users.${userParams.username} = {
    xdg.desktopEntries.steam = {
      name = "Steam";
      exec = "steam-gamescope";
      terminal = false;
      type = "Application";
    };
  };

  # Kinda works with portal2, but with serious input lag:
  # env DXVK_ASYNC=1 SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 3840 -H 2160 -r 160 -o 160 --borderless --fullscreen --rt --steam  -- %command% |& tee /tmp/game.log

  # nixpkgs.config.packageOverrides = pkgs: {
  #   steam = pkgs.steam.override {
  #     extraPkgs = pkgs: with pkgs; [
  #       xorg.libXcursor
  #       xorg.libXi
  #       xorg.libXinerama
  #       xorg.libXScrnSaver
  #       libpng
  #       libpulseaudio
  #       libvorbis
  #       stdenv.cc.cc.lib
  #       libkrb5
  #       keyutils
  #     ];
  #   };
  # };
}
