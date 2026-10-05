# Base system packages installed on every host
{ config, pkgs, inputs, system, ... }:
let userParams = config.hostParams.user; in
{
  programs.nix-ld.enable = true;
  # OFF, and it has to be: the module's dbPath defaults to
  # `pkgs.path + "/programs.sqlite"`, a file that only exists in a nixpkgs
  # CHANNEL tarball, never in a flake checkout. Until the 2026-10-01 nixpkgs
  # bump that non-existent path just became a dangling derivation reference
  # (so the handler failed at runtime and nobody noticed); trivial-builders
  # moving to finalAttrs/lib.toFunction now coerces it during
  # derivationStrict, so eval itself dies with "path
  # '«github:NixOS/nixpkgs/...»/programs.sqlite' does not exist" and no host
  # builds. Nothing is lost -- `nix-index` is in the package list below and
  # is what nixpkgs itself points flake users at.
  programs.command-not-found.enable = false;
  programs.mosh.enable = true;
  programs.zsh.enable = if userParams.shell == "zsh" then true else false;

  environment.systemPackages = with pkgs; [
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.lxml
      python-pkgs.requests
      python-pkgs.pip
      python-pkgs.virtualenv
      python-pkgs.yt-dlp
      python-pkgs.curl-cffi
    ]))
    appimage-run
    at-spi2-core
    axel
    backblaze-b2
    bashmount
    bc
    bfg-repo-cleaner
    bind
    bridge-utils
    cabextract
    ccze
    cdrkit
    chromaprint      # fpcalc: audio fingerprint — the cheap half of "is this the same video re-encoded"
    cowsay
    cpufrequtils
    cyme
    distrobox
    dmidecode
    dos2unix
    ed
    efibootmgr
    elixir
    eternal-terminal
    exfat
    exiftool
    fbset
    fclones          # exact-content dedup (blake3 + reflink/hardlink); the pass to run before any perceptual one
    ffmpeg
    file
    fio
    fx
    gcc
    gdb
    gettext
    git
    git-lfs
    glow
    gnumake
    gnupg
    gparted
    gptfdisk
    htop
    hwinfo
    iftop
    imagemagick
    inetutils
    iotop
    iperf3
    libarchive
    lm_sensors
    lsb-release
    lshw
    lsof
    luarocks
    lxqt.lxqt-policykit
    iw
    iwd
    jhead
    memtest86plus
    minicom
    mokutil
    msr-tools
    fastfetch
    nethogs
    networkmanager
    nh
    nix
    nix-output-monitor
    nix-prefetch-github
    nixos-generators
    nil
    nix-index
    nvd
    nvme-cli
    nvtopPackages.full
    openssl
    p7zip
    parted
    pciutils
    powertop
    pstree
    pv
    ryzenadj
    socat
    sqlite
    sshpass
    steam-run
    steampipe
    stress-ng
    swtpm
    sysstat
    tmux
    udev
    libudev-zero
    udevil
    udisks
    unrar
    usbutils
    util-linux
    vim
    vulnix
    wireguard-tools
    wirelesstools
    wget
    xorriso
    xz
    yt-dlp
    zip
    zsh

    # cd/dvd ripping/recovery
    cdparanoia
    ddrescue
    flac
    whipper
  ];
}
