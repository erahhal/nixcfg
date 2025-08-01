{
  description = "NixOS configuration with flakes";

  inputs = {
    # Use stable for main
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Should match nixpkgs version
    # home-manager.url = "github:nix-community/home-manager/release-24.05";
    # home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.url = "github:nix-community/home-manager";
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

    sops-nix.url = "github:Mic92/sops-nix";

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
    # dcc.url = "path:flakes/dcc";
    # dcc.inputs.nixpkgs.follows = "nixpkgs";

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
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # hyprland.url = "git+https://github.com/erahhal/Hyprland?submodules=1";

    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    # };

    swayfx.url = "github:willpower3309/swayfx";
    swayfx.inputs.nixpkgs.follows = "nixpkgs";

    nixd.url = "github:nix-community/nixd";

    comma.url = "github:nix-community/comma";

    sg-nvim.url = "github:sourcegraph/sg.nvim";

    nix-inspect.url = "github:bluskript/nix-inspect";

    nflx.url = "git+ssh://git@github.com/erahhal/nixcfg-nflx";
    # nflx.url = "path:/home/erahhal/Code/nixcfg-nflx";

    nflx-vpn = {
      url = "git+ssh://git@github.com/erahhal/nixcfg-nflx-vpn";
      # url = "path:/home/erahhal/Code/nixcfg-nflx-vpn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets.url = "git+ssh://git@github.com/erahhal/nixcfg-secrets";
    # secrets.url = "path:/home/erahhal/Code/nixcfg-secrets";

    nixvim-config.url = "git+https://git.homefree.host/homefree/nixvim-config";
    # nixvim-config.url = "path:/home/erahhal/Code/nixvim-config";

    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { ... }@inputs:
  let
    recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
    userParams = import ./user-params.nix {};
    homeManagerConfig = {
      ## Make sure it restarts after rebuilding system config
      systemd.services."home-manager-${userParams.username}".serviceConfig = { RemainAfterExit = "yes"; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      nixpkgs.overlays = [ inputs.nur.overlays.default ];
    };
  in {
    # lib.pkgsParameters = {
    #   overlays = [ ];
    #   buildSystem = null; # same as host system
    #   config = {
    #     allowUnsupportedSystem = true;
    #   };
    # };
    homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = {
        inherit userParams;
        inherit recursiveMerge;
      };
    };
    nixosConfigurations = rec {
      nflx-erahhal-p16 =
      let
        system = "x86_64-linux";
        copyDesktopIcons = inputs.erosanix.lib."${system}".copyDesktopIcons;
        copyDesktopItems = inputs.erosanix.lib."${system}".copyDesktopIcons;
        mkWindowsApp = inputs.erosanix.lib.x86_64-linux.mkWindowsApp;
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/nflx-erahhal-p16/host-params.nix
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          ./hosts/nflx-erahhal-p16/configuration.nix
          inputs.secrets.nixosModules.nflx-erahhal-p16
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p16s-intel-gen2
          inputs.nur.modules.nixos.default
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig

          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = false;
            nixvim-config.enable-startify-cowsay = true;
          }
          inputs.nflx-vpn.nixosModules.default
          inputs.nflx.nixosModules.default
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit copyDesktopIcons;
          inherit copyDesktopItems;
          inherit mkWindowsApp;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
      nflx-erahhal-x1c =
      let
        system = "x86_64-linux";
        copyDesktopIcons = inputs.erosanix.lib."${system}".copyDesktopIcons;
        copyDesktopItems = inputs.erosanix.lib."${system}".copyDesktopIcons;
        mkWindowsApp = inputs.erosanix.lib.x86_64-linux.mkWindowsApp;
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/nflx-erahhal-x1c/host-params.nix
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          ./hosts/nflx-erahhal-x1c/configuration.nix
          inputs.secrets.nixosModules.nflx-erahhal-x1c
          # inputs.jovian.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen
          inputs.nur.modules.nixos.default
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig

          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = true;
            nixvim-config.enable-startify-cowsay = true;
          }
          inputs.nflx-vpn.nixosModules.default
          inputs.nflx.nixosModules.default

          # inputs.nix-snapd.nixosModules.default
          # {
          #   services.snap.enable = true;
          # }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit copyDesktopIcons;
          inherit copyDesktopItems;
          inherit mkWindowsApp;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
      antikythera =
      let
        system = "x86_64-linux";
        copyDesktopIcons = inputs.erosanix.lib."${system}".copyDesktopIcons;
        copyDesktopItems = inputs.erosanix.lib."${system}".copyDesktopIcons;
        mkWindowsApp = inputs.erosanix.lib.x86_64-linux.mkWindowsApp;
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/antikythera/host-params.nix
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          ./hosts/antikythera/configuration.nix
          inputs.secrets.nixosModules.antikythera
          inputs.jovian.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          # @TODO: Switch to gen5 when available
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5
          inputs.nur.modules.nixos.default
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig

          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = false;
            nixvim-config.enable-startify-cowsay = true;
          }
          # inputs.nix-snapd.nixosModules.default
          # {
          #   services.snap.enable = true;
          # }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
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
        recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/upaya/host-params.nix
          ./hosts/upaya/configuration.nix
          inputs.secrets.nixosModules.upaya
          inputs.jovian.nixosModules.default
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.nixos-hardware.nixosModules.dell-xps-15-9560
          # inputs.nixos-hardware-xps.nixosModules.common-cpu-intel
          # inputs.nixos-hardware-xps.nixosModules.common-cpu-intel-kaby-lake
          # inputs.nixos-hardware-xps.nixosModules.common-pc-laptop
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig
          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = true;
            nixvim-config.enable-startify-cowsay = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
      sicmundus =
      let
        system = "x86_64-linux";
        recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/sicmundus/host-params.nix
          ./hosts/sicmundus/configuration.nix
          inputs.secrets.nixosModules.sicmundus
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig
          inputs.nur.modules.nixos.default
          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = true;
            nixvim-config.enable-startify-cowsay = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
      msi-desktop =
      let
        system = "x86_64-linux";
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/msi-desktop/host-params.nix
          ./hosts/msi-desktop/configuration.nix
          inputs.nixos-wsl.nixosModules.default
          {
            wsl.enable = true;
            wsl.defaultUser = userParams.username;
          }
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.secrets.nixosModules.msi-desktop
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig
          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = false;
            nixvim-config.enable-startify-cowsay = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit recursiveMerge;
          inherit userParams;
        };
      };

      ## Default hostname for WSL is nixos
      ## Will be renamed to msi-desktop after first installation
      nixos = msi-desktop;

      msi-linux =
      let
        system = "x86_64-linux";
        header-space = "      ";
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/host-params.nix
          ./hosts/msi-linux/host-params.nix
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          ./hosts/msi-linux/configuration.nix
          inputs.flake-utils-plus.nixosModules.autoGenFromInputs
          inputs.secrets.nixosModules.msi-linux
          inputs.jovian.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          homeManagerConfig

          inputs.nixvim-config.nixosModules.default
          {
            nixvim-config.enable = true;
            nixvim-config.enable-ai = false;
            nixvim-config.enable-startify-cowsay = true;
          }
          # inputs.nix-snapd.nixosModules.default
          # {
          #   services.snap.enable = true;
          # }
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit recursiveMerge;
          inherit userParams;
        };
      };
    };
  };
}
