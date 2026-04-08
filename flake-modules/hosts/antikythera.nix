{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.antikythera = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "antikythera"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {
      enable = true;
      enable-ai = true;
      enable-startify-cowsay = true;
      disable-indent-blankline = true;
      disable-notifications = true;
    }
    ++ (with self.nixosModules; [
      desktop niri dms hyprland
      pipewire
      fonts
      chromium-based-apps
      tailscale
      mullvad
      kdeconnect
      wireless
      wifi-qos
      homefree
      captive-portal
      exclusive-lan
      gfx-amd laptop udev-rules
      thinkpad-dock-udev
      appimage
      android
      totp
      steam
      waydroid
      snapcast
      nfs-mounts
      virtual-machines macchanger printers-scanners
      flatpak
      flox
      spacenavd
      connection-sharing
    ])
    ++ [
      inputs.dms-shell.nixosModules.default
      inputs.dms-shell.nixosModules.greeter
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.secrets.nixosModules.antikythera
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];
  };
}
