{ pkgs, inputs, lib, userParams, ... }:
let
  hyprland = pkgs.hyprland;
  # hyprland = pkgs.trunk.hyprland;
  # hyprland = pkgs.unstable.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland-debug;
  steam-gamescope-runtime-paths = lib.makeBinPath [
    hyprland
    pkgs.jq
    pkgs.gamescope
  ];
  steam-gamescope-script = pkgs.writeShellScriptBin "steam-gamescope-script" ''
    WIDTH=$(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .width")
    HEIGHT=$(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .height")
    gamescope \
      --steam \
      -W $WIDTH \
      -w $WIDTH \
      -H $HEIGHT \
      -h $HEIGHT \
      --fullscreen \
      --borderless \
      --backend wayland \
      --force-grab-cursor \
      --cursor-scale-height $HEIGHT \
      --adaptive-sync \
      -- steam -tenfoot -pipewire-dmabuf
  '';
in
let
  steam-gs = pkgs.stdenv.mkDerivation {
    name = "steam-gs";

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    installPhase = ''
      install -Dm755 ${steam-gamescope-script}/bin/steam-gamescope-script $out/bin/steam-gs

      wrapProgram $out/bin/steam-gs \
        --suffix PATH : ${steam-gamescope-runtime-paths}
    '';
  };
in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    protonup
    steam-tui
    steamcmd
    steam-gs
  ];

  home-manager.users.${userParams.username} = {
    xdg.desktopEntries.steam-gamescope = {
      name = "SteamGs";
      exec = "steam-gs";
      terminal = false;
      type = "Application";
      icon = "steam";
    };
  };
}
