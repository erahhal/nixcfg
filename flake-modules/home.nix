{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  debugMode = inputs.debug-mode.value;
  broken = import ../lib/broken.nix {
    inherit lib;
    pkgs = import inputs.nixpkgs {
      localSystem = "x86_64-linux";
      config.allowBroken = true;
    };
  };
  # Standalone home-manager config needs user values directly (no NixOS module system)
  userParams = { username = "erahhal"; fullName = "Ellis Rahhal"; shell = "zsh"; tty = "foot"; };
in
{
  flake.homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = {
      inherit debugMode;
      inherit userParams;
      inherit broken;
    };
  };
}
