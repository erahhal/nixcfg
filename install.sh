#!/usr/bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
 
if [ "$(readlink -- "/etc/nixos")" != $SCRIPTPATH ]; then
  if [ -e /etc/nixos ]; then
    sudo mv /etc/nixos /etc/nixos.orig
  fi
  sudo ln -s $SCRIPTPATH /etc/nixos
fi

sudo nixos-rebuild switch --flake .#${HOSTNAME} -L 
