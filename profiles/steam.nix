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
        ''-f''
        ''-r 60''
        ''--expose-wayland''
        ''--backend wayland''
        ''--force-grab-cursor''
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
