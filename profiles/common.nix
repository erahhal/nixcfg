{ config, pkgs, inputs, system, userParams, ...}:
{

  # --------------------------------------------------------------------------------------
  # Base Nix config
  # --------------------------------------------------------------------------------------

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "21.11"; # Did you read the comment?
  system.stateVersion = "23.11"; # Did you read the comment?

  # system.autoUpgrade = {
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
    package = pkgs.nixFlakes;

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
        # @TODO: Unclear if this should be part of the host machine or the raspberry pi nixcfg repo
        "https://arm.cachix.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "arm.cachix.org-1:5BZ2kjoL1q6nWhlnrbAl+G7ThY7+HaBRD9PZzqZkbnM="
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
      '';

    registry.nixpkgs.flake = inputs.nixpkgs;

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

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
        };
        trunk = import inputs.nixpkgs-trunk {
          config = config.nixpkgs.config;
          inherit system;
        };
        erahhal = import inputs.nixpkgs-erahhal {
          config = config.nixpkgs.config;
          inherit system;
        };
      };
    };
  };

  # Gives access to the NUR (Nix User Repository): https://github.com/nix-community/NUR
  nixpkgs.overlays = [
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

  # Disables writing to Nix store by mounting read-only. "false" should only be used as a last resort.
  # Nix mounts read-write automatically when it needs to write to it.
  boot.readOnlyNixStore = true;

  # "natively" run appimages
  # https://nixos.wiki/wiki/Appimage
  # Unfortunately, causes full rebuild of many packages
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # --------------------------------------------------------------------------------------
  # Services
  # --------------------------------------------------------------------------------------

  # Firmware/BIOS updates
  services.fwupd.enable = true;

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  ## Used for debugging DNS calls
  # systemd.services.systemd-resolved = {
  #   serviceConfig = {
  #     Environment = "SYSTEMD_LOG_LEVEL=debug";
  #   };
  # };

  # Setting to true will kill things like tmux on logout
  services.logind.killUserProcesses = false;

  # network locator e.g. scanners and printers
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  services.gvfs.enable = true; # SMB mounts, trash, and other functionality
  services.tumbler.enable = true; # Thumbnail support for images

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # @TODO: Move to "environment"?
  services.printing.drivers = [ pkgs.brlaser ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This will save you money and possibly your life!
  services.thermald.enable = true;

  services.upower.enable = true;

  # Enable power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # --------------------------------------------------------------------------------------
  # i18n
  # --------------------------------------------------------------------------------------

  i18n.defaultLocale = "en_US.UTF-8";

  # --------------------------------------------------------------------------------------
  # Networking
  # --------------------------------------------------------------------------------------

  networking.search = [ "localdomain" ];

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
    # ../overlays/steam-with-nvidia-offload.nix
    # ../overlays/blender-with-nvidia-offload.nix

    ## Fixes broken pam for screen lockers but requires rebuild of everything
    # ../overlays/pam-patched.nix

    ../profiles/overrides.nix
  ];

  # --------------------------------------------------------------------------------------
  # System users
  # --------------------------------------------------------------------------------------

  # Needed for running newt docker images that use systemd
  users = {
    groups.www-data = {
      gid = 33;
    };
    # Used by metatron and newt auth-proxy. host user needs to be part of this group
    groups.nac = {
      gid = 60243;
    };
    users.www-data = {
      isSystemUser  = true;
      description  = "www-data";
      group = "www-data";
      extraGroups = [
        "users"
      ];
      uid = 33;
    };
  };


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
    bfg-repo-cleaner
    bind
    blender
    ccze             # readable system log parser
    cdrkit           # provides genisoimage
    cpufrequtils
    distrobox
    dmidecode
    dos2unix
    exfat
    exiftool
    ffmpeg
    file
    fio
    fx                # Terminal-based JSON viewer and processor
    gcc
    git
    git-lfs
    gnumake
    htop
    hwinfo
    iftop
    inetutils
    iotop
    iperf3
    libarchive   # provides bsdtar
    luarocks
    lshw
    lsof
    lxqt.lxqt-policykit # For GVFS
    iw
    iwd
    jhead
    memtest86plus
    minicom
    neofetch
    nixos-generators
    unstable.nil
    nix-index
    openssl
    # openjdk16-bootstrap
    p7zip
    pciutils
    powertop
    pv
    networkmanager
    sshpass
    steam-run
    steampipe
    tmux
    unrar
    usbutils
    utillinux
    vim
    vulnix
    wireguard-tools
    wget
    xorriso
    xz
    zip
    zsh
  ];
}
