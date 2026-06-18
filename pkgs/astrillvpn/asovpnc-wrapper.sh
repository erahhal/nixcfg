#!/bin/sh
# Astrill's bundled OpenVPN (asovpnc, "2022.10.11 Astrill Edition") was NOT built
# with --iproute support, but astrill appends `--iproute <ip>` to the connector
# command whenever it finds an `ip` (iproute2) binary on PATH. asovpnc then aborts
# with "Unrecognized option: iproute" before opening its management socket, which
# astrill reports as "Error connecting to VPN client Management Interface".
#
# Strip `--iproute <arg>` here so OpenVPN parses cleanly and falls back to its
# net-tools (route/ifconfig) routing. The real binary sits next to us as
# .asovpnc-real; ambient capabilities (cap_net_admin/cap_net_raw) flow through.
# @REAL@ is substituted with the absolute store path at build time.
real="@REAL@"
args=
skip=0
for a in "$@"; do
  if [ "$skip" = 1 ]; then
    skip=0
    continue
  fi
  if [ "$a" = "--iproute" ]; then
    skip=1
    continue
  fi
  args="$args $a"
done
# args contain no whitespace (server IPs, ports, option flags), so word-splitting
# on re-expansion is safe and intentional.
exec "$real" $args
