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
  recursiveMerge = import ../lib/recursive-merge.nix { inherit lib; };
  userParams = import ../user-params.nix {};
in
{
  flake.homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = {
      inherit debugMode;
      inherit userParams;
      inherit broken;
      inherit recursiveMerge;
    };
  };
}
