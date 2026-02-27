# mkHost.nix - Helper to reduce boilerplate in flake.nix host definitions
#
# Usage:
#   mkHost {
#     hostName = "my-host";
#     modules = [ ... ];           # Host-specific modules (on top of the common set)
#   }
#
# Common modules included automatically:
#   - ./modules/host-params.nix
#   - ./hosts/<hostName>/host-params.nix
#   - ./hosts/<hostName>/configuration.nix
#   - flake-utils-plus autoGenFromInputs
#   - home-manager + homeManagerConfig
#   - nixvim-config (with configurable options)
#

{ inputs, userParams, debugMode, broken, recursiveMerge, homeManagerConfig }:

{
  hostName,
  system ? "x86_64-linux",
  modules ? [],
  nixvimConfig ? {
    enable = true;
    enable-ai = false;
    enable-startify-cowsay = true;
    disable-indent-blankline = true;
  },
}:

let
  lib = inputs.nixpkgs.lib;

  # Build the nixvim module from the config attrset
  nixvimModule = {
    nixvim-config = {
      enable = nixvimConfig.enable or true;
      enable-ai = nixvimConfig.enable-ai or false;
      enable-startify-cowsay = nixvimConfig.enable-startify-cowsay or true;
      disable-indent-blankline = nixvimConfig.disable-indent-blankline or true;
    } // (lib.optionalAttrs (nixvimConfig ? disable-notifications) {
      disable-notifications = nixvimConfig.disable-notifications;
    });
  };

  # Erosanix specialArgs - kept for backward compat with any packages that may need them
  erosanixArgs = {
    copyDesktopIcons = inputs.erosanix.lib."${system}".copyDesktopIcons;
    copyDesktopItems = inputs.erosanix.lib."${system}".copyDesktopIcons;
    mkWindowsApp = inputs.erosanix.lib."${system}".mkWindowsApp;
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    # Common base modules included for every host
    ../modules/host-params.nix
    ../hosts/${hostName}/host-params.nix
    ../hosts/${hostName}/configuration.nix
    inputs.flake-utils-plus.nixosModules.autoGenFromInputs
    inputs.home-manager.nixosModules.home-manager
    homeManagerConfig

    # Nixvim
    inputs.nixvim-config.nixosModules.default
    nixvimModule
  ]
  # Host-specific modules
  ++ modules;

  specialArgs = {
    inherit debugMode inputs system broken recursiveMerge userParams;
  } // erosanixArgs;
}
