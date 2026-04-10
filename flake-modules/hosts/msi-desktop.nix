{ self, inputs, ... }:
let
  shared = import ../../lib/shared.nix { inherit inputs; };
  cfg = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = shared.specialArgs;
    modules = shared.baseModules "msi-desktop"
    ++ [ shared.homeManagerConfig ]
    ++ shared.nixvimModule {}
    ++ (with self.nixosModules; [
      tailscale
    ])
    ++ [
      inputs.nixos-wsl.nixosModules.default
      inputs.dms-shell.nixosModules.default
      inputs.dms-shell.nixosModules.greeter
      inputs.nix-flatpak.nixosModules.nix-flatpak
      ({ config, ... }: {
        wsl.enable = true;
        wsl.defaultUser = config.hostParams.user.username;
      })
      inputs.secrets.nixosModules.msi-desktop
    ];
  };
in
{
  flake.nixosConfigurations = {
    msi-desktop = cfg;
    ## Default hostname for WSL is nixos
    ## Will be renamed to msi-desktop after first installation
    nixos = cfg;
  };
}
