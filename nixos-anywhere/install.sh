#!/usr/bin/env bash

echo 'Installation steps:'
echo ''
echo '  - Make sure configuration has your SSH key authorized for root so you can change your password, e.g.'
echo '       users.users.root.openssh.authorizedKeys.keys = ['
echo '         "ssh-rsa blahblah"'
echo '       ];'
echo '  - Boot minimal NixOS image on target'
echo '  - On target: Change password with `passwd`'
echo '  - On source: `scp ~/.ssh/authorized_keys nixos@<address>:/home/nixos`'
echo '  - On target: `mkdir -p ~/.ssh; mv ~/authorized_keys ~/.ssh/authorized_keys'
echo '  - Then continue by entering the values below'
echo ''

read -p "Enter IP Address: " ADDRESS

if [[ $ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  read -p "Enter host configuration name: " CONFIG_NAME
  if [ -z "${CONFIG_NAME}" ]; then
    echo "Empty name"
    exit
  fi
else
  echo "Invalid IP Address"
  exit
fi

echo "IP: ${ADDRESS}"
echo "Config: ${CONFIG_NAME}"
echo ""
read -p "ARE YOU SURE? This will DESTROY the target (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

cd $DIR

nix run github:nix-community/nixos-anywhere -- --flake ../#${CONFIG_NAME} nixos@$ADDRESS