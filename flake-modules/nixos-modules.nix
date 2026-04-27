# Registers NixOS feature modules.
# Exported as flake.nixosModules.* for reuse by other flakes.
# Modules use `key` attributes for deduplication when also imported internally.
{ inputs, ... }: {
  flake.nixosModules = {
    # Desktop
    desktop = import ../modules/desktop;
    hyprland = import ../modules/desktop/hyprland;
    plasma = import ../modules/desktop/plasma;
    sddm = import ../modules/desktop/sddm;
    pipewire = import ../modules/desktop/pipewire;
    fonts = import ../modules/desktop/fonts;
    chromium-based-apps = import ../modules/desktop/chromium-based-apps;

    # Networking
    tailscale = import ../modules/networking/tailscale;
    mullvad = import ../modules/networking/mullvad;
    kdeconnect = import ../modules/networking/kdeconnect;
    wireless = import ../modules/networking/wireless;
    wifi-qos = import ../modules/networking/wifi-qos;
    homefree = import ../modules/networking/homefree;
    captive-portal = import ../modules/networking/captive-portal;
    exclusive-lan = import ../modules/networking/exclusive-lan;
    connection-sharing = import ../modules/networking/connection-sharing;

    # Hardware
    gfx-amd = import ../modules/hardware/gfx-amd;
    gfx-intel = import ../modules/hardware/gfx-intel;
    gfx-nvidia = import ../modules/hardware/gfx-nvidia;
    laptop = import ../modules/hardware/laptop;
    udev-rules = import ../modules/hardware/udev-rules;
    thinkpad-dock-udev = import ../modules/hardware/thinkpad-dock-udev;
    openrgb = import ../modules/hardware/openrgb;
    keyboard-debounce = import ../modules/hardware/keyboard-debounce;
    spacenavd = import ../modules/hardware/spacenavd;
    ryzenadj = import ../modules/hardware/ryzenadj;

    # Programs
    steam = import ../modules/programs/steam;
    flatpak = import ../modules/programs/flatpak;
    appimage = import ../modules/programs/appimage;
    android = import ../modules/programs/android;
    totp = import ../modules/programs/totp;
    dell-dcc = import ../modules/programs/dell-dcc;
    flox = import ../modules/programs/flox;

    # Services
    waydroid = import ../modules/services/waydroid;
    snapcast = import ../modules/services/snapcast;
    nfs-mounts = import ../modules/services/nfs-mounts;
    virtual-machines = import ../modules/services/virtual-machines;
    macchanger = import ../modules/services/macchanger;
    printers-scanners = import ../modules/services/printers-scanners;
  };
}
