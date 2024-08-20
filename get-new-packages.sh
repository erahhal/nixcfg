#!/usr/bin/env bash

nix build --override-input nixpkgs github:NixOS/nixpkgs/nixos-24.05 -v .#nixosConfigurations."nflx-erahhal-x1c".config.system.build.toplevel
nvd diff /run/current-system result
rm result
