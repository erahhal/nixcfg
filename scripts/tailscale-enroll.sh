#!/usr/bin/env bash


if sudo [ -f /run/secrets/tailscale/key ]; then
  sudo tailscale up --auth-key=$(sudo cat /run/secrets/tailscale/key) --login-server=https://vpn.homefree.host --accept-routes
  systemctl restart tailscaled-autoconnect
else
  echo "Get a key here:"
  echo "https://vpn.homefree.host/admin"
  echo "Then add to secrets at tailscale/key"
fi
