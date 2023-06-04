HOSTNAME = $(shell hostname)

NIX_FILES = $(shell find . -name '*.nix' -type f)

ifndef HOSTNAME
 $(error Hostname unknown)
endif

switch:
	make clear-sddm-cache
	make clear-mimeapps
	nixos-rebuild --use-remote-sudo switch --show-trace --flake .#${HOSTNAME} -L
	make update-gnupg-perms

offline:
	nixos-rebuild --use-remote-sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L

boot:
	nixos-rebuild --use-remote-sudo boot --flake .#${HOSTNAME} -L

test:
	nixos-rebuild --use-remote-sudo test --flake .#${HOSTNAME} -L

update:
	nix flake update

update-local:
	nix flake lock --update-input remarkable --update-input dcc --update-input pulse-secure

upgrade:
	make update && make switch

clear-sddm-cache:
	sudo ./build/clear-sddm-cache

clear-mimeapps:
	[ -L "${HOME}/.config/mimeapps.list" ] || rm -f ${HOME}/.config/mimeapps.list

update-gnupg-perms:
	chmod 700 ${HOME}/.gnupg

update-nixpkgs:
	git submodule init
	git submodule update --remote nixpkgs
	cd nixpkgs; git config remote.upstream.url >&- || git remote add upstream https://github.com/NixOS/nixpkgs.git
	cd nixpkgs; git fetch upstream
	cd nixpkgs; git pull --rebase upstream master


