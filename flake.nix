{
  description = "NixOS configuration with flakes";

  inputs = {
    # Use stable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    # Should match nixpkgs version
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Trails trunk - latest packages with broken commits filtered out
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Very latest packages - some commits broken
    nixpkgs-trunk.url = "github:NixOS/nixpkgs";

    # Updated packages: blender
    nixpkgs-erahhal.url = "github:erahhal/nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Nix User Repository
    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    # Run unpatched dynamic binaries
    # Set NIX_LD_LIBRARY_PATH and NIX_LD
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets management
    agenix.url = "github:ryantm/agenix";

    # sway/wlroots
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # # Wine wrapper
    # erosanix.url = github:emmanuelrosa/erosanix;
    # erosanix.inputs.nixpkgs.follows = "nixpkgs";

    # Remarkable 2 Tablet Desktop App WINE wrapper
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    remarkable.url = "path:flakes/remarkable";
    remarkable.inputs.nixpkgs.follows = "nixpkgs";

    # DCC
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    dcc.url = "path:flakes/dcc";
    dcc.inputs.nixpkgs.follows = "nixpkgs";

    # Pulse Secure
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    pulse-secure.url = "path:flakes/pulse-secure";
    pulse-secure.inputs.nixpkgs.follows = "nixpkgs";

    # Base16 color schemes
    base16.url = "github:SenchoPens/base16.nix";
    base16.inputs.nixpkgs.follows = "nixpkgs";

    base16-eva-scheme = {
      url = "github:kjakapat/base16-eva-scheme";
      flake = false;
    };

    mms.url = "github:mkaito/nixos-modded-minecraft-servers";
    mms.inputs.nixpkgs.follows = "nixpkgs";

    nix-software-center.url = "github:vlinkz/nix-software-center";

    # Hyprland WM
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nflx.url = "git+ssh://git@github.com/erahhal/nixcfg-nflx";

    secrets.url = "git+ssh://git@github.com/erahhal/nixcfg-secrets";
  };

  outputs = { ... }@inputs:
  let
    userParams = import ./user-params.nix {};
    recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
  in {
    # Secrets
    modules = [
    ];
    homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        inputs.hyprland.homeManagerModules.default
        { wayland.windowManager.hyprland.enable = true; }
      ];
    };
    nixosConfigurations = {
      nflx-erahhal-t490s =
      let
        system = "x86_64-linux";
        hostParams = import ./hosts/nflx-erahhal-t490s/params.nix {};
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          (import ./hosts/nflx-erahhal-t490s/configuration.nix)
          inputs.agenix.nixosModules.default
          inputs.secrets.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          # @TODO: Make this generic and move into hosts?
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 # No t490s yet
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-laptop
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          inputs.nix-ld.nixosModules.nix-ld
          inputs.nflx.nixosModules.default
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit userParams;
          inherit recursiveMerge;
        };
      };
      upaya =
      let
        system = "x86_64-linux";
        hostParams = import ./hosts/upaya/params.nix {};
        userParams = import ./user-params.nix {};
        recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          (import ./hosts/upaya/configuration.nix)
          inputs.agenix.nixosModules.default
          inputs.secrets.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.dell-xps-15-9560
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-laptop
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          inputs.nix-ld.nixosModules.nix-ld

          inputs.base16.nixosModule
          { scheme = "${inputs.base16-eva-scheme}/eva.yaml"; }
          hosts/upaya/theming.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit userParams;
          inherit recursiveMerge;
        };
      };
      sicmundus =
      let
        system = "x86_64-linux";
        hostParams = import ./hosts/sicmundus/params.nix {};
        userParams = import ./user-params.nix {};
        recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          (import ./hosts/sicmundus/configuration.nix)
          inputs.agenix.nixosModules.default
          inputs.secrets.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          inputs.nix-ld.nixosModules.nix-ld
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit userParams;
          inherit recursiveMerge;
        };
      };
    };
  };
}
