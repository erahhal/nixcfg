# Base system packages installed on every host
{ config, pkgs, inputs, system, ... }:
let userParams = config.hostParams.user; in
{
  programs.nix-ld.enable = true;
  programs.command-not-found.enable = true;
  programs.command-not-found.dbPath = "${inputs.nixpkgs}/programs.sqlite";
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
    cowsay
    cpufrequtils
    cyme
    distrobox
    dmidecode
    dos2unix
    ed
    elixir
    eternal-terminal
    exfat
    exiftool
    fbset
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
    nvtopPackages.full
    openssl
    p7zip
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
