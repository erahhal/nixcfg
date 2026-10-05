# Nix daemon, flake, garbage collection, and registry configuration
{ config, lib, pkgs, inputs, system, ... }:
let userParams = config.hostParams.user; in
{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      sandbox = true;

      # OFF DELIBERATELY -- this is the "build looks frozen" setting. With it
      # on, the daemon hardlink-dedupes every path INLINE as it is
      # substituted, and `daemonCPUSchedPolicy = "idle"` /
      # `daemonIOSchedClass = "idle"` below mean it does that work at idle
      # priority while builders block behind it on log backpressure. During a
      # mass rebuild (e.g. the GCC 16 window of 2026-10) that reads as a
      # hung switch rather than a slow one. The `nix.optimise` timer further
      # down already dedupes weekly, out of band, which is where that work
      # belongs. Note this flag has been `true` since the 2023-06-03 initial
      # commit; it was never the cause of a regression, just never turned off.
      auto-optimise-store = false;

      # Collect every independent failure in ONE pass. Without this, nix stops
      # at the first failed derivation, so a flake bump that breaks three
      # unrelated packages costs three full build rounds to discover -- which
      # is exactly what the 2026-10-01 nixpkgs bump cost (eternal-terminal,
      # then gimp-with-plugins, then grantlee, an hour apiece).
      keep-going = true;

      # Keep the machine usable during a mass rebuild. The NixOS defaults are
      # `max-jobs = auto` and `cores = 0`, i.e. on antikythera up to 16
      # concurrent derivations EACH allowed all 16 logical cores; load average
      # hit 30.7 during the 2026-10-01 bump. Rule of thumb is
      # max-jobs * cores ~= core count. Throughput barely changes -- the box
      # was already saturated -- but the desktop stays responsive.
      #
      # mkDefault because this is a module shared by every host: a bigger
      # build box (logistikon) wants a larger pair, and one big job like
      # llama-cpp is badly served by cores = 4. Override per host.
      max-jobs = lib.mkDefault 4;
      cores = lib.mkDefault 4;
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

      '' + (if config.age.secrets ? "nix-config" then ''
        !include ${config.age.secrets."nix-config".path}
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
