Instead of `../../scripts` in `home.file."Scripts".source`:

```nix
# ./users/erahhal/default.nix

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules
    ];

  home.username = "erahhal";
  home.homeDirectory = "/home/erahhal";

  programs.home-manager.enable = true;

  home.file."Scripts".source = ../../scripts;
}                      # HERE: ^^^^^^^^^^^^^
```

One can pass `self` to each file that imports `./users/erahhal/default.nix` in
order to resolve the path relative to the `flake.nix` at the root of the repo.

First in `flake.nix`

```nix
{
  description = "Matthew's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-wayland.url = "github:colemickens/nixpkgs-wayland";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, home-manager, nixpkgs, ... }: {
    nixosConfigurations = {
      t480 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import ./hosts/t480/configuration.nix)
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = import ./users self;
          }                             # HERE: ^^^^
        ];
      };
    };
  };
}
```
Then in the first layer of the import  `./users/default.nix`

```nix
# ./users/default.nix
self: # <- explicitly declaring self

{
  erahhal = import ./erahhal self;
}
```

Then in the next layer of the import  `./users/erahhal/default.nix`

```nix
# ./users/erahhal/default.nix
self: # <- explicitly declaring self

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules
    ];

  home.username = "erahhal";
  home.homeDirectory = "/home/erahhal";

  programs.home-manager.enable = true;

  home.file."Scripts".source = "${self}/scripts";
}                             # ^^^^^^^ <- string interpolating 'self' to reveal relative path from flake.nix at root of repo.
```
