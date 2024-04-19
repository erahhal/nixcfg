COOKBOOK
========

Various information and commands and techniques to get things done.

### Kernel versioning

* Unstable always takes the latest LTS release
* Stable sticks with the LTS at the time of the first release
* Stable also provides a backport of the latest from unstable (linuxPackages_latest)

### Running a package flake from a github repo

`nix run github:bluskript/nix-inpsect`

### Read-Eval-Print Loop (REPL)

`nix repl`
`nix repl --expr 'import <nixpkgs>{}`

### nix eval

Get derivation params

`nix eval -f '<nixpkgs>' 'vscode.version'`

Get list of all packages

`nix eval nixpkgs#legacyPackages.x86_64-linux --apply builtins.attrNames`

Get list of linux packages

`nix eval nixpkgs#legacyPackages.x86_64-linux.linuxPackages --apply builtins.attrNames`

Get linux kernel version (not necessarily the installed one)

`nix eval nixpkgs#legacyPackages.x86_64-linux.linuxPackages.kernel.baseVersion --apply builtins.attrNames`

Get list of builtins

`nix eval nixpkgs#lib --apply builtins.attrNames`

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
