#!/usr/bin/env bash

pw-dump | jq -r '[.[] | select(.info.props."node.name" | IN("firefox","gnome-shell","kwin_wayland","obs","xdg-desktop-portal-wlr","xdp-screencast.py")) | .id] as $pw_node_ids | [ .[] | select(.info.props."node.id" | IN($pw_node_ids[])) | .id ] as $pw_port_ids | .[] | select(.id | IN(($pw_node_ids + $pw_port_ids)[]))'
