{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.upaya = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "upaya"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {
      enable = true;
      enable-ai = true;
      enable-startify-cowsay = true;
      disable-indent-blankline = true;
    }
    ++ (with self.nixosModules; [
      desktop
      pipewire
      fonts
      mullvad
      kdeconnect
      wireless
      captive-portal
      exclusive-lan
      gfx-nvidia gfx-intel laptop udev-rules
      appimage
      android
      dell-dcc
      waydroid
      nfs-mounts
      virtual-machines macchanger printers-scanners
      flatpak
      flox
      spacenavd
      connection-sharing
    ])
    ++ [
      inputs.secrets.nixosModules.upaya
      inputs.dms-shell.nixosModules.default
      inputs.dms-shell.nixosModules.greeter
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.nixos-hardware.nixosModules.dell-xps-15-9560
    ];
  };
}
