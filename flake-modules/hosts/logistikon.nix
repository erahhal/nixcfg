{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.logistikon = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "locortex"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {}
    ++ (with self.nixosModules; [
      desktop hyprland
      pipewire
      fonts
      chromium-based-apps
      mullvad
      kdeconnect
      gfx-nvidia gfx-intel laptop udev-rules
      openrgb
      keyboard-debounce
      nfs-mounts
      android
      flatpak
      flox
      switchyard
      spacenavd
      connection-sharing
    ])
    ++ [
      inputs.nixcfg-niri.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.secrets.nixosModules.logistikon
      inputs.nix-flatpak.nixosModules.nix-flatpak
      # inputs.steam-loader.nixosModules.default
      # {
      #   programs.steam-loader.enable = true;
      # }
    ];
  };
}
