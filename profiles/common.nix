{ config, lib, pkgs, inputs, system, userParams, ...}:
# let
#   backblaze-b2 = (pkgs.runCommandLocal "backblaze-b2" { meta.broken = true; } (lib.warn "Package backblaze-b2 is currently disabled" "mkdir -p $out"));
# in
{

  # --------------------------------------------------------------------------------------
  # Base Nix config
  # --------------------------------------------------------------------------------------

  # system.autoUpgrade = {c
  #   enable = true;
  #   allowReboot = true;
  #   flake = "github:erahhal/nixcfg";
  #   flags = [
  #     "--recreate-lock-file"
  #     "-no-write-lock-file"
  #     "-L" # print build logs
  #   ];
  #   dates = "daily";
  # };

  nix = {
    # Which package collection to use system-wide.

    # package = pkgs.nixUnstable;
    package = pkgs.nixVersions.latest;

    settings = {
      # sets up an isolated environment for each build process to improve reproducibility.
      # Disallow network callsoutside of fetch* and files outside of the Nix store.
      sandbox = true;
      # Automatically clean out old entries from nix store by detecting duplicates and creating hard links.
      # Only starts with new derivations, so run "nix-store --optimise" to clear out older cruft.
      # optimise.automatic = true below should handle this.
      auto-optimise-store = true;
      # Users with additional Nix daemon rights.
      # Can specify additional binary caches, import unsigned NARs (Nix Archives).
      trusted-users = [ "@wheel" "root" ];
      # Users allowed to connect to Nix daemon
      allowed-users = [ "@wheel" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
        "https://arm.cachix.org/"
        "https://robotnix.cachix.org/"
        "https://cache.flox.dev"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "arm.cachix.org-1:5BZ2kjoL1q6nWhlnrbAl+G7ThY7+HaBRD9PZzqZkbnM="
        "robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];
    };
    # Additional text appended to nix.conf
    extraOptions =
      let empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}''; in
      ''
        # Enable flakes
        experimental-features = nix-command flakes recursive-nix
        flake-registry = ${empty_registry}

        builders-use-substitutes = true

        # Prevents garbage collector from deleting derivations.
        # Useful for querying and tracing options and dependencies for a store path.
        # https://ianthehenry.com/posts/how-to-learn-nix/saving-your-shell/
        keep-derivations = true

        # Prevents garbage collector from deleting outputs of derivations.
        keep-outputs = true

        # Create a "fine grained access token" with no extra permissions:
        # https://github.com/settings/personal-access-tokens/new
        !include ${config.sops.secrets."nix-config".path}
      '';

    registry.nixpkgs.flake = inputs.nixpkgs;

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # Performance - don't kill the machine while building
    # 0 (high) to 7 (low), default 4
    daemonIOSchedPriority = 6;
    # "best-effort" | "idle"
    daemonIOSchedClass = "idle";
    # "batch" (high) | "other" (normal) | "idle" (low)
    daemonCPUSchedPolicy = "idle";

    # Garbage collection - deletes all unreachable paths in Nix store.
    gc = {
      # Run garbage collection automatically
      automatic = true;
      # Run once a week
      dates = "weekly";
      # Delete older than 7 days, stopping after "max-freed" bytes
      options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
    };
    # Optimiser settings
    # It seems that this is a scheduled job, as opposed to "autoOptimiseStore", which runs just in time.
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # NOTE HERE that keys can be defined multiple times in a set. If the value is another set, the
  # keys of the value of merged.

  # From flake-utils-plus, a library to easily generate flake configurations.
  nix = {
    # Generates NIX_PATH from available inputs.
    # NIX_PATH is used to resolve angle brackets, e.g. <name>, in nix expressions.
    generateNixPathFromInputs = true;
    # Generates nix.registry from flake inputs. nix.registry is a system-wide flake registry.
    generateRegistryFromInputs = true;
    # Symlink inputs to /etc/nix/inputs.
    linkInputs = true;
  };

  # --------------------------------------------------------------------------------------
  # Package config
  # --------------------------------------------------------------------------------------

  nixpkgs = {
    config = {
      # Allow proprietary packages.
      allowUnfree = true;
      # Allow broken packages.
      allowBroken = true;
      packageOverrides = pkgs: {
        unstable = import inputs.nixpkgs-unstable {
          config = config.nixpkgs.config;
          inherit system;
          # (import ../overlays/hyprland-patched.nix)
        };
        trunk = import inputs.nixpkgs-trunk {
          config = config.nixpkgs.config;
          inherit system;
        };
        erahhal = import inputs.nixpkgs-erahhal {
          config = config.nixpkgs.config;
          inherit system;
        };
        nixpkgs-windsurf = import inputs.nixpkgs-windsurf {
          config = config.nixpkgs.config;
          inherit system;
        };
      };
    };
  };

  # Gives access to the NUR (Nix User Repository): https://github.com/nix-community/NUR
  nixpkgs.overlays = [
    # @TODO: full overlay can cause rebuilds - install as package instead?
    inputs.comma.overlays.default
    (final: prev: {
      ## Use SwayFX
      # sway-unwrapped = inputs.swayfx.packages.${prev.system}.default;
    })
  ];

  # --------------------------------------------------------------------------------------
  # Boot / Kernel
  # --------------------------------------------------------------------------------------

  # boot.kernelPackages = pkgs.linuxPackages_hardened;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
  ## Detect crashes
  # boot.crashDump.enable = true;
  # services.das_watchdog.enable = true;

  ## To address issues with neovim nvimtree plugin
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 1024;
  };

  # --------------------------------------------------------------------------------------
  # Services
  # --------------------------------------------------------------------------------------

  services.ntp.enable = true;

  systemd.coredump.enable = true;

  # Firmware/BIOS updates
  services.fwupd.enable = true;

  ## Used for debugging DNS calls
  # systemd.services.systemd-resolved = {
  #   serviceConfig = {
  #     Environment = "SYSTEMD_LOG_LEVEL=debug";
  #   };
  # };

  # Setting to true will kill things like tmux on logout
  services.logind.killUserProcesses = false;

  # network locator e.g. scanners, printers, media devices, etc
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  services.eternal-terminal.enable = true;
  # et port
  networking.firewall.allowedTCPPorts = [ 2022 ];
  environment.variables = {
    ET_NO_TELEMETRY = "1";
  };


  services.gvfs.enable = true; # SMB mounts, trash, and other functionality
  services.tumbler.enable = true; # Thumbnail support for images

  ## Mount optical disks automatically
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="sr0", ENV{DISK_MEDIA_CHANGE}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart devmon@$env{USER}.service"
  '';

  security.wrappers.udevil = {
    owner = "root";
    group = "root";
    source = "${pkgs.udevil}/bin/udevil";
    setuid = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This will save you money and possibly your life!
  services.thermald.enable = true;

  services.upower.enable = true;

  # --------------------------------------------------------------------------------------
  # i18n
  # --------------------------------------------------------------------------------------

  i18n.defaultLocale = "en_US.UTF-8";

  # --------------------------------------------------------------------------------------
  # Networking
  # --------------------------------------------------------------------------------------

  networking.search = [ ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # --------------------------------------------------------------------------------------
  # App without home-manager support
  # @TODO: Put these in a better place
  # --------------------------------------------------------------------------------------

  imports = [
    ./gfx-nvidia.nix
    ./gfx-amd.nix
    ./gfx-intel.nix
    ../modules/macchanger.nix

    # ../overlays/steam-with-nvidia-offload.nix
    # ../overlays/blender-with-nvidia-offload.nix

    ## Fixes broken pam for screen lockers but requires rebuild of everything
    # ../overlays/pam-patched.nix

    # ../profiles/overrides.nix
    ../profiles/printers-scanners.nix
    ../profiles/flox.nix

    ../nixos-anywhere/connection-sharing.nix
  ];

  # --------------------------------------------------------------------------------------
  # Base Packages
  # --------------------------------------------------------------------------------------

  programs.nix-ld.enable = true;

  programs.command-not-found.enable = true;
  programs.command-not-found.dbPath = "${inputs.nixpkgs}/programs.sqlite";

  programs.mosh.enable = true;

  programs.zsh = {
    enable = if userParams.shell == "zsh" then true else false;
  };

  environment.systemPackages = with pkgs; [
    appimage-run
    at-spi2-core
    axel
    backblaze-b2
    bashmount
    bc
    bfg-repo-cleaner
    bind
    cabextract
    ccze             # readable system log parser
    cdrkit           # provides genisoimage
    cowsay
    cpufrequtils
    distrobox
    dmidecode
    dos2unix
    ed
    eternal-terminal
    exfat
    exiftool
    ffmpeg
    file
    fio
    fx                # Terminal-based JSON viewer and processor
    gcc
    gdb
    gettext
    git
    git-lfs
    glow
    gnumake
    gnupg
    gparted # need to be installed as system, not user package
    htop
    hwinfo
    iftop
    inetutils
    iotop
    iperf3
    libarchive   # provides bsdtar
    lm_sensors
    lsb-release
    lshw
    lsof
    luarocks
    lxqt.lxqt-policykit # For GVFS
    iw
    iwd
    jhead
    memtest86plus
    minicom
    mokutil
    neofetch
    nethogs
    networkmanager
    nix
    nix-output-monitor
    nixos-generators
    nil
    nix-index
    nvd
    nvtopPackages.full
    openssl
    # openjdk16-bootstrap
    p7zip
    pciutils
    powertop
    pstree
    pv
    ryzenadj
    sambaFull # to get rid of wine ntml_auth errors
    sqlite
    sshpass
    steam-run
    steampipe
    stress-ng
    sysstat
    tmux
    udev
    libudev-zero
    udevil
    udisks
    unrar
    usbutils
    utillinux
    vim
    vulnix
    wireguard-tools
    wirelesstools
    wget
    xorriso
    xz
    zip
    zsh
    inputs.nix-inspect.packages.${system}.default
  ];
}
