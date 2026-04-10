{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.programs.steam;

  steam-gamescope-runtime-paths = lib.makeBinPath [
    pkgs.hyprland
    pkgs.niri
    pkgs.jq
    pkgs.gamescope
    pkgs.gnugrep
    pkgs.coreutils
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
      --borderless \
      --force-grab-cursor \
      --cursor-scale-height $HEIGHT \
      --adaptive-sync \
      -- steam -tenfoot -pipewire-dmabuf
  '';

  steam-gs = pkgs.stdenv.mkDerivation {
    name = "steam-gs";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      install -Dm755 ${steam-gamescope-script}/bin/steam-gamescope-script $out/bin/steam-gs
      wrapProgram $out/bin/steam-gs \
        --suffix PATH : ${steam-gamescope-runtime-paths}
    '';
  };
in {
  options.nixcfg.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming";
    gamescope.enable = lib.mkEnableOption "Steam Gamescope desktop entry";
  };
  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };

    hardware.steam-hardware.enable = true;

    environment.systemPackages = with pkgs; [
      gamemode
      gamescope
      protonup-ng
      steam-tui
      steamcmd
      steam-gs
    ];

    home-manager.users.${userParams.username} = lib.mkIf cfg.gamescope.enable {
      xdg.desktopEntries.steam-gamescope = {
        name = "SteamGs";
        exec = "steam-gs";
        terminal = false;
        type = "Application";
        icon = "steam";
      };
    };
  };
}
