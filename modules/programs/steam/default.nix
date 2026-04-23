{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.programs.steam;

  mkGamescopeScript = import ../../../lib/mkGamescopeScript.nix { inherit pkgs lib config; };

  steam-gs = mkGamescopeScript {
    name = "steam-gs";
    innerCommand = "steam -tenfoot -pipewire-dmabuf";
  };
in {
  options.nixcfg.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming";
    gamescope.enable = lib.mkEnableOption "Steam Gamescope desktop entry";
  };
  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
        };
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };

    hardware.steam-hardware.enable = true;

    environment.systemPackages = with pkgs; [
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
