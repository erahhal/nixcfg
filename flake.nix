{
  description = "NixOS configuration with flakes";

  inputs = {
    debug-mode.url = "github:boolean-option/false";

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

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-shell = {
      # url = "github:AvengeMedia/DankMaterialShell/11e23feb0e233147afbd5f15ea68043c4492029b";
      url = "github:AvengeMedia/DankMaterialShell/v1.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-loader = {
      url = "path:./profiles/steam-loader";
    };

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

    # Software KVM - use flake for latest with modifier key fix (PR #238)
    lan-mouse.url = "github:feschber/lan-mouse";
    lan-mouse.inputs.nixpkgs.follows = "nixpkgs";

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

    nflx-nixcfg = {
      type = "git";
      url = "git+ssh://git@github.com/netflix/nflx-nixcfg.git";
      ref = "main";
      # ref = "recovery-updates";
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

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0"; # Use latest stable

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { debug-mode, ... }@inputs:
  let
    debugMode = debug-mode.value;
    broken = import ./helpers/broken.nix {
      lib = inputs.nixpkgs.lib;
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowBroken = true;
      };
    };
    recursiveMerge = import ./helpers/recursive-merge.nix { lib = inputs.nixpkgs.lib; };
    userParams = import ./user-params.nix {};
    homeManagerConfig = {
      ## Make sure it restarts after rebuilding system config
      systemd.services."home-manager-${userParams.username}".serviceConfig = { RemainAfterExit = "yes"; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      # Note: nixpkgs.overlays moved to profiles/common.nix (not allowed with useGlobalPkgs)
      home-manager.users.${userParams.username} = {config, ...}: {
        imports = [
          inputs.caelestia-shell.homeManagerModules.default
          inputs.dms-shell.homeModules.dank-material-shell
          inputs.lan-mouse.homeManagerModules.default
          inputs.nix-colors.homeManagerModules.default
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.steam-loader.homeManagerModules.default
        ];
      };
    };
    mkHost = import ./lib/mkHost.nix {
      inherit inputs userParams debugMode broken recursiveMerge homeManagerConfig;
    };
  in {
    homeConfigurations.${userParams.username} = inputs.home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = {
        inherit debugMode;
        inherit userParams;
        inherit broken;
        inherit recursiveMerge;
      };
    };
    nixosConfigurations = rec {

      # -----------------------------------------------------------------------
      # nflx-erahhal-p16 - Work laptop (Lenovo ThinkPad P16s)
      # -----------------------------------------------------------------------
      nflx-erahhal-p16 = mkHost {
        hostName = "nflx-erahhal-p16";
        modules = [
          {
            ## @TODO: TEMPORARY
            nixpkgs.config.permittedInsecurePackages = [
              "libsoup-2.74.3"
            ];
          }
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.secrets.nixosModules.nflx-erahhal-p16
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p16s-intel-gen2
          inputs.nur.modules.nixos.default
          inputs.dms-shell.nixosModules.dank-material-shell
          inputs.nix-flatpak.nixosModules.nix-flatpak
          { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; }
          # inputs.nflx-nixcfg.nixosModules.pulse-vpn
          inputs.nflx-nixcfg.nixosModules.default
          {
            nflx = {
              username = "erahhal";
              system = {
                enable-systemd-resolved = true;
              };
              development = {
                java.enable = true;
                # newt.clean-tmux-nesting = true;
                workspaces.disable-workspace-id-warning = true;
              };
              genai = {
                project-id = "erahhaldevtools";
                context = {
                  enable-dx-team = true;
                };
              };
              vpn.pulse = {
                # url = "https://lax001.pcs.flxvpn.net/emp-split";
                # enable-nm-applet-service = true;
                # enable-dtls = false;
                # enable-selenium = true;
                disable-url-warning = true;
                disable-nm-applet-warning = true;
              };
            };
          }
        ];
      };

      # -----------------------------------------------------------------------
      # antikythera - Personal laptop (Lenovo ThinkPad P14s AMD Gen5)
      # -----------------------------------------------------------------------
      antikythera = mkHost {
        hostName = "antikythera";
        nixvimConfig = {
          enable = true;
          enable-ai = true;
          enable-startify-cowsay = true;
          disable-indent-blankline = true;
          disable-notifications = true;
        };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.secrets.nixosModules.antikythera
          inputs.jovian.nixosModules.default
          # @TODO: Switch to gen5 when available
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5
          inputs.nur.modules.nixos.default
          inputs.dms-shell.nixosModules.dank-material-shell
          inputs.nix-flatpak.nixosModules.nix-flatpak
        ];
      };

      # -----------------------------------------------------------------------
      # upaya - Dell XPS 15 9560
      # -----------------------------------------------------------------------
      upaya = mkHost {
        hostName = "upaya";
        nixvimConfig = {
          enable = true;
          enable-ai = true;
          enable-startify-cowsay = true;
          disable-indent-blankline = true;
        };
        modules = [
          inputs.secrets.nixosModules.upaya
          inputs.jovian.nixosModules.default
          inputs.nixos-hardware.nixosModules.dell-xps-15-9560
        ];
      };

      # -----------------------------------------------------------------------
      # sicmundus - Server
      # -----------------------------------------------------------------------
      sicmundus = mkHost {
        hostName = "sicmundus";
        nixvimConfig = {
          enable = true;
          enable-ai = true;
          enable-startify-cowsay = true;
          disable-indent-blankline = true;
        };
        modules = [
          inputs.secrets.nixosModules.sicmundus
          inputs.nur.modules.nixos.default
        ];
      };

      # -----------------------------------------------------------------------
      # msi-desktop - WSL on MSI desktop
      # -----------------------------------------------------------------------
      msi-desktop = mkHost {
        hostName = "msi-desktop";
        modules = [
          inputs.nixos-wsl.nixosModules.default
          {
            wsl.enable = true;
            wsl.defaultUser = userParams.username;
          }
          inputs.secrets.nixosModules.msi-desktop
        ];
      };

      ## Default hostname for WSL is nixos
      ## Will be renamed to msi-desktop after first installation
      nixos = msi-desktop;

      # -----------------------------------------------------------------------
      # msi-linux - MSI desktop native Linux
      # -----------------------------------------------------------------------
      msi-linux = mkHost {
        hostName = "msi-linux";
        modules = [
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.secrets.nixosModules.msi-linux
          inputs.dms-shell.nixosModules.dank-material-shell
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.steam-loader.nixosModules.default
          {
            programs.steam-loader.enable = true;
          }
        ];
      };

    };
  };
}
