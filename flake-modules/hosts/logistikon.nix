{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.logistikon = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "logistikon"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {}
    ++ (with self.nixosModules; [
      desktop hyprland
      pipewire
      fonts
      chromium-based-apps
      mullvad
      kdeconnect
      gfx-nvidia gfx-amd udev-rules
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
      # The stack, and the private half of its model catalog. Two modules
      # because the catalog is this host's choice, not the stack's: the
      # second only adds entries, and they merge because the shipped
      # catalog ships at mkDefault priority. Drop the second line and this
      # box runs the same stack with the published models only.
      inputs.genai-server.nixosModules.default
      inputs.genai-server-private.nixosModules.default
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
