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

    switchyard = {
      url = "github:alyraffauf/switchyard";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcfg-niri = {
      url = "github:erahhal/nixcfg-niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-loader = {
      url = "path:./modules/programs/steam-loader";
    };

    # Home-manager theming
    nix-colors.url = "github:misterio77/nix-colors";

    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

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
      # Use the `release` branch -- it's the one xddxdd's Hydra builds and
      # uploads to the attic.xuyh0120.win/lantian cache. The default
      # (`master`) branch tracks the latest CachyOS source and has no
      # pre-built artifacts, so building against it compiles the kernel
      # locally.
      #
      # IMPORTANT: do NOT make this flake follow our nixpkgs. The kernel
      # in xddxdd's binary cache is built against the *flake's own* pinned
      # nixpkgs revision; if we override that, every input differs and we
      # get cache misses on a 24+ MiB kernel build. The trade-off is that
      # the cachy flake brings in a separate nixpkgs at evaluation time,
      # but it's only used to produce the kernel derivation -- runtime
      # impact is nil.
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

  };

  outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    imports = (inputs.import-tree ./flake-modules).imports;
  };
}
