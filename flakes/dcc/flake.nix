{
  description = "Dell Commad Configure tool";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };

    in with pkgs; {
      dcc = callPackage ./dcc.nix {
        inherit builtins;
      };
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.dcc;
  };
}
