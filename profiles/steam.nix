{ config, pkgs, lib, userParams, ... }:
let
  steam-gamescope-runtime-paths = lib.makeBinPath [
    pkgs.hyprland
    pkgs.jq
    pkgs.gamescope
  ];

  ## Starting fullscreen seems to lock mouse movement within bounds
  ## Start the game in windowed mode, then hit mod-f to go fullscreen after play starts to avoid this
  ## UPDATE: NOPE, this just worked twice, probably coincidentally, then started getting stuck again
  ## Probably has nothing to do with fullscreen setting.
      # --fullscreen \

  ## This isn't needed
      # --backend wayland \

  steam-gamescope-script = pkgs.writeShellScriptBin "steam-gamescope-script" ''
    WIDTH=$(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .width")
    HEIGHT=$(hyprctl monitors -j | jq ".[] | select(.id==$(hyprctl activeworkspace -j | jq '.monitorID')) | .height")
    gamescope \
      --steam \
      -W $WIDTH \
      -w $WIDTH \
      -H $HEIGHT \
      -h $HEIGHT \
      --borderless \
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
    gamescopeSession.enable = true;
  };

  # programs.gamescope = {
  #   enable = true;
  #   # make sure gamescope runs at full performance
  #   capSysNice = true;
  # };

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    protonup
    steam-tui
    steamcmd
    steam-gs
  ];

  home-manager.users.${userParams.username} = lib.mkIf config.hostParams.programs.steam.enableGamescope {
    xdg.desktopEntries.steam-gamescope = {
      name = "SteamGs";
      exec = "steam-gs";
      terminal = false;
      type = "Application";
      icon = "steam";
    };
  };
}
