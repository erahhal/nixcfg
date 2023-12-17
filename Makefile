HOSTNAME = $(shell hostname)
THEME = dark-mode

NIX_FILES = $(shell find . -name '*.nix' -type f)

ifndef HOSTNAME
 $(error Hostname unknown)
endif

switch:
	make clear-sddm-cache
	make clear-mimeapps
	make clear-gpu-cache
	echo Building ${THEME}
	nixos-rebuild --use-remote-sudo switch --flake .#${HOSTNAME} -L --specialisation ${THEME}
	make update-gnupg-perms
	tmux source-file ~/.tmux.conf

dark-mode: THEME=dark-mode
dark-mode: switch

light-mode: THEME=light-mode
light-mode: switch

show-trace:
	make clear-sddm-cache
	make clear-mimeapps
	nixos-rebuild --use-remote-sudo switch --show-trace --flake .#${HOSTNAME} -L
	make update-gnupg-perms

offline:
	nixos-rebuild --use-remote-sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L

clear-gpu-cache:
	find ~/.config/. -type d -name GPUCache -exec rm -rf {} +

gc:
	nix-store --gc
	nix-env --delete-generations old

boot:
	nixos-rebuild --use-remote-sudo boot --flake .#${HOSTNAME} -L

test:
	nixos-rebuild --use-remote-sudo test --flake .#${HOSTNAME} -L

update:
	nix flake update

update-local:
	nix flake lock --update-input remarkable --update-input dcc

update-nflx:
	nix flake lock --update-input nflx

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


