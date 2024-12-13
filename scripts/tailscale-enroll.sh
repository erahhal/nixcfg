#!/usr/bin/env bash


if sudo [ -f /run/secrets/tailscale/key ]; then
  sudo tailscale up --auth-key=$(sudo cat /run/secrets/tailscale/key) --login-server=https://headscale.homefree.host --accept-routes
  systemctl restart tailscaled-autoconnect
else
  echo "Get a key here:"
  echo "https://headscale.homefree.host/web/users.html"
  echo "Then add to secrets at tailscale/key"
fi
