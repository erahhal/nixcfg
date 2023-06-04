{
  description = "A Nix flake for then Remarkable Desktop App";

  inputs.erosanix.url = "github:emmanuelrosa/erosanix";
  inputs.erosanix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, erosanix }: {

    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };

    in with (pkgs // erosanix.packages.x86_64-linux // erosanix.lib.x86_64-linux); {
      remarkable = callPackage ./remarkable.nix {
        inherit builtins mkWindowsApp makeDesktopIcon copyDesktopIcons;

        wine = wineWowPackages.full;
      };
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.remarkable;
  };
}
