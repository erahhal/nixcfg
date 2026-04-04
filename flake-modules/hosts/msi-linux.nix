{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.msi-linux = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "msi-linux"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {}
    ++ (with self.nixosModules; [
      desktop niri dms hyprland
      pipewire
      fonts
      chromium-based-apps
      tailscale
      mullvad
      kdeconnect
      gfx-nvidia gfx-intel laptop udev-rules
      openrgb
      keyboard-debounce
      nfs-mounts
    ])
    ++ [
      inputs.dms-shell.nixosModules.default
      inputs.dms-shell.nixosModules.greeter
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.secrets.nixosModules.msi-linux
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.steam-loader.nixosModules.default
      {
        programs.steam-loader.enable = true;
      }
    ];
  };
}
