# Shared values and module lists for host configurations.
# Each host flake-parts module imports this and calls nixosSystem directly.

{ inputs }:

let
  lib = inputs.nixpkgs.lib;

  debugMode = inputs.debug-mode.value;
  broken = import ./broken.nix {
    inherit lib;
    pkgs = import inputs.nixpkgs {
      localSystem = "x86_64-linux";
      config.allowBroken = true;
    };
  };
in {
  specialArgs = {
    inherit debugMode inputs broken;
    system = "x86_64-linux";
  };

  # Base modules included for every host
  baseModules = hostName: [
    ./host-params.nix
    ../modules/hosts/${hostName}/host-params.nix
    ../modules/hosts/${hostName}/configuration.nix
    # Base system
    ../modules/system/nix-config
    ../modules/system/overlays
    ../modules/system/boot
    ../modules/system/security
    ../modules/system/services
    ../modules/system/base-packages
    ../modules/system/networking
    ../modules/hardware/base
    ../modules/base-user
    # Flake integrations
    inputs.flake-utils-plus.nixosModules.autoGenFromInputs
    inputs.home-manager.nixosModules.home-manager
  ];

  # Home-manager base wiring (included for every host)
  homeManagerConfig = { config, ... }: {
    systemd.services."home-manager-${config.hostParams.user.username}".serviceConfig = { RemainAfterExit = "yes"; };
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${config.hostParams.user.username} = {config, ...}: {
      imports = [
        inputs.nixcfg-niri.homeModules.dms-shell
        inputs.nixcfg-niri.homeModules.niri
        inputs.nixcfg-niri.homeModules.startup-apps
        inputs.lan-mouse.homeManagerModules.default
        inputs.nix-colors.homeManagerModules.default
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.steam-loader.homeManagerModules.default
      ];
    };
  };

  # Nixvim module with configurable options
  nixvimModule = nixvimConfig: [
    inputs.nixvim-config.nixosModules.default
    {
      nixvim-config = {
        enable = nixvimConfig.enable or true;
        enable-ai = nixvimConfig.enable-ai or false;
        enable-startify-cowsay = nixvimConfig.enable-startify-cowsay or true;
        disable-indent-blankline = nixvimConfig.disable-indent-blankline or true;
      } // (lib.optionalAttrs (nixvimConfig ? disable-notifications) {
        disable-notifications = nixvimConfig.disable-notifications;
      });
    }
  ];
}
