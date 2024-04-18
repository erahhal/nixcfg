COOKBOOK
========

Various commands and techniques to get things done.

### Running a package flake from a github repo

`nix run github:bluskript/nix-inpsect`

### Read-Eval-Print Loop (REPL)

`nix repl`
`nix repl --expr 'import <nixpkgs>{}`

### Determining where config is defined, which can be used to debug issues such as conflicts

In an attempt to find out why conflicting Nvidia drivers were being built, I was told by ElvishJerricco on Element to try the following:

`nix eval .#nixosConfigurations.upaya.options.boot.extraModulePackages.definitionsWithLocations --apply 'map (x: x.file)'`

`nix eval .#nixosConfigurations.upaya.options.boot.extraModulePackages.definitionsWithLocations --apply 'xs: builtins.listToAttrs (map (x: { name = toString x.file; value = toString x.value; }) xs)'`

In the process, it turns out that using

```
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    (import ./hosts/upaya/configuration.nix)`
  ];
};
```

kills debug information, and is better done as:

```
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    ./hosts/upaya/configuration.nix
  ];
};
```
