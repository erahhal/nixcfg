{
  description = "NixOS configuration with flakes";

  inputs = {
    # Use stable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # Should match nixpkgs version
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Trails trunk - latest packages with broken commits filtered out
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Very latest packages - some commits broken
    nixpkgs-trunk.url = "github:NixOS/nixpkgs";

    # Updated packages: blender
    nixpkgs-erahhal.url = "github:erahhal/nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    ## @TODO: Get rid of this when nvidia is re-enabled in repo, and also update to latest zfs kernel
    nixos-hardware-xps.url = "github:NixOS/nixos-hardware/af21850d3d3937460378f1a46834fca54397292c";

    # Nix User Repository
    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    nix-snapd.url = "github:io12/nix-snapd";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets management
    agenix.url = "github:ryantm/agenix";

    # Wine wrapper
    erosanix.url = "github:emmanuelrosa/erosanix";
    erosanix.inputs.nixpkgs.follows = "nixpkgs";

    flox.url = "github:flox/flox";

    # Remarkable 2 Tablet Desktop App WINE wrapper
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    # remarkable.url = "path:flakes/remarkable";
    # remarkable.inputs.nixpkgs.follows = "nixpkgs";

    # DCC
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    dcc.url = "path:flakes/dcc";
    dcc.inputs.nixpkgs.follows = "nixpkgs";

    # Pulse Secure
    # See the following about why relative paths can cause build issues:
    #   https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    # pulse-secure.url = "path:flakes/pulse-secure";
    # pulse-secure.inputs.nixpkgs.follows = "nixpkgs";

    # Home-manager theming
    nix-colors.url = "github:misterio77/nix-colors";

    mms.url = "github:mkaito/nixos-modded-minecraft-servers";
    mms.inputs.nixpkgs.follows = "nixpkgs";

    nix-software-center.url = "github:vlinkz/nix-software-center";

    # Hyprland WM
    # hyprland = {
    #   url = "github:hyprwm/hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };
    # hyprland-contrib = {
    #   url = "github:hyprwm/contrib";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };

    swayfx.url = "github:willpower3309/swayfx";
    swayfx.inputs.nixpkgs.follows = "nixpkgs";

    nixd.url = "github:nix-community/nixd";

    comma.url = "github:nix-community/comma";

    sg-nvim.url = "github:sourcegraph/sg.nvim";

    nflx.url = "git+ssh://git@github.com/erahhal/nixcfg-nflx";
    # nflx.url = "path:/home/erahhal/Code/nixcfg-nflx";

    nflx-vpn.url = "git+ssh://git@github.com/erahhal/nixcfg-nflx-vpn";
    # nflx-vpn.url = "path:/home/erahhal/Code/nixcfg-nflx-vpn";

    secrets.url = "git+ssh://git@github.com/erahhal/nixcfg-secrets";
    # secrets.url = "path:/home/erahhal/Code/nixcfg-secrets";
  };

  outputs = { ... }@inputs:
  let
    userParams = import ./user-params.nix {};
    recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
  in {
    # lib.pkgsParameters = {
    #   overlays = [ ];
    #   buildSystem = null; # same as host system
    #   config = {
    #     allowUnsupportedSystem = true;
    #   };
    # };
    homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
      # modules = [
      #   inputs.hyprland.homeManagerModules.default
      # ];
      extraSpecialArgs = {
        inherit userParams;
        inherit recursiveMerge;
      };
    };
    nixosConfigurations = {
      mediaserver =
      let
        system = "aarch64-linux";
        hostParams = import ./hosts/mediaserver/params.nix {};
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          (import ./hosts/mediaserver/configuration.nix)
          inputs.agenix.nixosModules.default
          inputs.secrets.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          inputs.nur.nixosModules.nur
          { nixpkgs.overlays = [ inputs.nur.overlay ]; }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            nixpkgs.overlays = [ inputs.nur.overlay ];
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
      nflx-erahhal-x1c =
      let
        system = "x86_64-linux";
        hostParams = import ./hosts/nflx-erahhal-x1c/params.nix {};
        copyDesktopIcons = inputs.erosanix.lib."${system}".copyDesktopIcons;
        copyDesktopItems = inputs.erosanix.lib."${system}".copyDesktopIcons;
        mkWindowsApp = inputs.erosanix.lib.x86_64-linux.mkWindowsApp;
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          (import ./hosts/nflx-erahhal-x1c/configuration.nix)
          inputs.agenix.nixosModules.default
          inputs.secrets.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen
          inputs.nur.nixosModules.nur
          { nixpkgs.overlays = [ inputs.nur.overlay ]; }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            nixpkgs.overlays = [ inputs.nur.overlay ];
          }
          inputs.nix-snapd.nixosModules.default
          {
            services.snap.enable = true;
          }
          inputs.nflx-vpn.nixosModules.default
          inputs.nflx.nixosModules.default
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit copyDesktopIcons;
          inherit copyDesktopItems;
          inherit mkWindowsApp;
          inherit recursiveMerge;
          inherit userParams;
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
          inputs.nixos-hardware-xps.nixosModules.dell-xps-15-9560
          inputs.nixos-hardware-xps.nixosModules.common-cpu-intel
          inputs.nixos-hardware-xps.nixosModules.common-pc-laptop
          inputs.home-manager.nixosModules.home-manager
          inputs.nur.nixosModules.nur
          { nixpkgs.overlays = [ inputs.nur.overlay ]; }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            nixpkgs.overlays = [ inputs.nur.overlay ];
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit recursiveMerge;
          inherit userParams;
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
          inputs.nur.nixosModules.nur
          { nixpkgs.overlays = [ inputs.nur.overlay ]; }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            nixpkgs.overlays = [ inputs.nur.overlay ];
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit hostParams;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
    };
  };
}
