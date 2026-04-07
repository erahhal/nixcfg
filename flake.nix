{
  description = "NixOS configuration with flakes";

  inputs = {
    debug-mode.url = "github:boolean-option/false";

    # Use unstable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Should match nixpkgs version
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

    flake-utils.url = "github:numtide/flake-utils";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    # flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    import-tree.url = "github:vic/import-tree";

    # Secrets management
    secrets.url = "git+ssh://git@github.com/erahhal/nixcfg-secrets";

    flox.url = "github:flox/flox";

    dms-shell = {
      url = "github:AvengeMedia/DankMaterialShell/v1.4.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-loader = {
      url = "path:./modules/programs/steam-loader";
    };

    # Home-manager theming
    nix-colors.url = "github:misterio77/nix-colors";

    # Software KVM - use flake for latest with modifier key fix (PR #238)
    lan-mouse.url = "github:feschber/lan-mouse";
    lan-mouse.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland WM
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    nixd.url = "github:nix-community/nixd";

    nflx-nixcfg = {
      type = "git";
      url = "git+ssh://git@github.com/netflix/nflx-nixcfg.git";
      ref = "main";
      # ref = "recovery-updates";
    };

    nixvim-config.url = "git+https://git.homefree.host/homefree/nixvim-config";

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

  outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    imports = (inputs.import-tree ./flake-modules).imports;
  };
}
