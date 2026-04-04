# Fix Tailscale DNS resolution for homefree.host domains

## Context

Tailscale is running and connected, but `homefree.host` domains fail to resolve. The Headscale split DNS routes `homefree.host` queries to `10.0.0.1` (home router/DNS). However, the `tailscale-local-route` systemd service adds a policy routing rule that sends ALL `10.0.0.0/24` traffic to the main routing table (bypassing Tailscale's tunnel). When away from the home network, this means DNS queries for `homefree.host` hit whatever device is at `10.0.0.1` on the current network (e.g., a corporate router), instead of being tunneled through Tailscale to the home network's DNS server.

## Change

Narrow the policy routing rule from `10.0.0.0/24` to `10.0.0.42/32` (the Synology NAS IP). This allows:
- NFS/SMB mounts to the NAS (10.0.0.42) to still bypass Tailscale and use the local network when at home
- DNS queries to 10.0.0.1 to go through Tailscale's tunnel, reaching the home DNS server

## File to modify

`/home/erahhal/Code/nixcfg/profiles/tailscale.nix` (lines 67-98)

Replace all occurrences of `10.0.0.0/24` with `10.0.0.42/32` in the `tailscale-local-route` service:
- Line 80 (ExecStop): `ip rule del to 10.0.0.42/32 lookup main priority 5200`
- Line 94: `ip rule del to 10.0.0.42/32 lookup main priority 5200`
- Line 95: `ip rule add to 10.0.0.42/32 lookup main priority 5200`
- Update comments on lines 67, 92, 96 to reflect the narrower scope

## Verification

1. Rebuild NixOS: `sudo nixos-rebuild switch --flake .`
2. Check the policy rule is narrowed: `ip rule show` — should show `to 10.0.0.42/32` not `10.0.0.0/24`
3. Test DNS resolution: `resolvectl query vpn.homefree.host` — should resolve
4. Test Tailscale peer connectivity: `tailscale ping 100.64.0.1` — should still work
5. When at home: verify NFS mounts to 10.0.0.42 still work via LAN
