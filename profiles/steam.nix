{ pkgs, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    protonup
  ];

  # Kinda works with portal2, but with serious input lag:
  # env DXVK_ASYNC=1 SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 3840 -H 2160 -r 160 -o 160 --borderless --fullscreen --rt --steam  -- %command% |& tee /tmp/game.log

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
      ];
    };
  };
}
