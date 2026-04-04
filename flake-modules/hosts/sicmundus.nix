{ self, inputs, ... }:
let
  mkNixosSystem = import ../../lib/mkNixosSystem.nix { inherit inputs; nixosModules = self.nixosModules; };
in
{
  flake.nixosConfigurations.sicmundus = mkNixosSystem {
    hostName = "sicmundus";
    nixvimConfig = {
      enable = true;
      enable-ai = true;
      enable-startify-cowsay = true;
      disable-indent-blankline = true;
    };
    modules = [
      inputs.secrets.nixosModules.sicmundus
      inputs.nur.modules.nixos.default
    ];
  };
}
