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
    inputs.stylix.nixosModules.stylix
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
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.steam-loader.homeManagerModules.default
      ];
    };
  };

  # Nixvim wired into home-manager so its generated config lives under
  # home-files (and therefore flips with the toggle-theme symlink swap).
  # Colorscheme follows the HM-level stylix.polarity (which the light-mode
  # HM specialisation flips to "light") unless explicitly overridden.
  nixvimModule = nixvimConfig: [
    ({ config, ... }:
    let
      username = config.hostParams.user.username;
    in {
      home-manager.users.${username} = hmArgs:
      let
        polarity = hmArgs.config.stylix.polarity;
        colorscheme =
          nixvimConfig.colorscheme
            or (if polarity == "light"
                then "tokyonight-day"
                else "tokyonight-storm");
      in {
        imports = [ inputs.nixvim-config.homeManagerModules.default ];
        nixvim-config = {
          enable = nixvimConfig.enable or true;
          enable-ai = nixvimConfig.enable-ai or false;
          enable-startify-cowsay = nixvimConfig.enable-startify-cowsay or true;
          disable-indent-blankline = nixvimConfig.disable-indent-blankline or true;
          inherit colorscheme;
        } // (lib.optionalAttrs (nixvimConfig ? disable-notifications) {
          disable-notifications = nixvimConfig.disable-notifications;
        });
        # Let stylix drive nixvim highlights only when colorscheme == "stylix";
        # otherwise keep tokyonight in charge.
        stylix.targets.nixvim.enable = colorscheme == "stylix";
      };
    })
  ];
}
