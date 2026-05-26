# AGENTS.md

## Builds

Never run `nix build`, `nixos-rebuild`, `home-manager switch`, or any other
build/realisation command without asking first. These commands can be slow,
pull large closures, and modify the running system. Always propose the
command and wait for explicit approval before executing.

When a build is approved, use `nix run .#switch` (the project's flake app)
unless you specifically need options that app doesn't expose. Propose any
deviation in the same approval request.
