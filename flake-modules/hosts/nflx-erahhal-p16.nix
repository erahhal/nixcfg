{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.nflx-erahhal-p16 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "nflx-erahhal-p16"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule { enable = true; enable-ai = true; }
    ++ (with self.nixosModules; [
      desktop hyprland
      pipewire fonts chromium-based-apps
      tailscale mullvad kdeconnect wireless wifi-qos
      homefree captive-portal exclusive-lan
      gfx-nvidia gfx-intel laptop udev-rules
      appimage android totp
      waydroid snapcast virtual-machines macchanger printers-scanners
      flatpak
      flox
      spacenavd
      connection-sharing
    ])
    ++ [
      inputs.nixcfg-niri.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.secrets.nixosModules.nflx-erahhal-p16
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p16s-intel-gen2
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.nflx-nixcfg.nixosModules.default
      ../../modules/hosts/nflx-erahhal-p16/nflx-nixcfg.nix
    ];
  };
}
