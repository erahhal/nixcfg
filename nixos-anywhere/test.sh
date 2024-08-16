#!/usr/bin/env bash

nix run github:nix-community/nixos-anywhere -- --flake ../hosts/antikythera/nixos-anywhere#antikythera --vm-test
