# Nix daemon, flake, garbage collection, and registry configuration
{ config, pkgs, inputs, system, userParams, ... }:
{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      sandbox = true;
      auto-optimise-store = true;
      trusted-users = [ "@wheel" "root" ];
      allowed-users = [ "@wheel" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
        "https://arm.cachix.org/"
        "https://robotnix.cachix.org/"
        "https://cache.flox.dev"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "arm.cachix.org-1:5BZ2kjoL1q6nWhlnrbAl+G7ThY7+HaBRD9PZzqZkbnM="
        "robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];

      download-buffer-size = 524288000;
      extra-platforms = [ "aarch64-linux" ];
    };

    extraOptions =
      let empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}''; in
      ''
        experimental-features = nix-command flakes recursive-nix
        flake-registry = ${empty_registry}

        builders-use-substitutes = true

        keep-derivations = true
        keep-outputs = true

      '' + (if config.sops.secrets ? "nix-config" then ''
        !include ${config.sops.secrets."nix-config".path}
      '' else "");

    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    daemonIOSchedPriority = 6;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # From flake-utils-plus
  nix = {
    generateNixPathFromInputs = true;
    generateRegistryFromInputs = true;
    linkInputs = true;
  };
}
