HOSTNAME = $(shell hostname)
NIX_FILES = $(shell find . -name '*.nix' -type f)
CURR_THEME = $(shell cat ~/.system-theme)

define n


endef

ifndef HOSTNAME
 $(error Hostname unknown)
endif

ifeq (, $(shell which nom))
 $(error "$n$nnom not in path. run nix-shell -p nix-output-monitor on first run")
endif

## nom currently broken, covers password prompt.
# NOM := nom 
# LOGFORMAT := --log-format internal-json
NOM := cat
LOGFORMAT := 

switch: 
	# make clear-sddm-cache
	make clear-mimeapps
	make clear-gpu-cache
	make clear-gtkrc
	# sudo true && nixos-rebuild ${LOGFORMAT} -v --sudo switch --flake .#${HOSTNAME} -L |& ${NOM}
	nixos-rebuild ${LOGFORMAT} --sudo switch --flake .#${HOSTNAME}
	# nixos-rebuild --sudo switch --flake .#${HOSTNAME} -L
	make update-gnupg-perms
	# Building defaults to dark, so switch back if it was light before
	NEW_THEME=$$(cat ~/.system-theme) ;\
	if [ "$(CURR_THEME)" != "$$NEW_THEME" ]; then \
		systemctl --user restart toggle-theme ;\
	fi

boot:
	nixos-rebuild --sudo boot --flake .#${HOSTNAME} -L
	

remote-install:
	./nixos-anywhere/install.sh

show-trace:
	make clear-sddm-cache
	make clear-mimeapps
	sudo true && nixos-rebuild ${LOGFORMAT} -v --sudo switch --show-trace --flake .#${HOSTNAME} -L |& ${NOM}
	# nixos-rebuild --sudo switch --show-trace --flake .#${HOSTNAME} -L
	make update-gnupg-perms

offline:
	sudo true && nixos-rebuild ${LOGFORMAT} -v --sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L |& ${NOM} 
	# nixos-rebuild -v --sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L

clear-gpu-cache:
	mkdir -p ~/.config
	find ~/.config/. -type d -name GPUCache -exec rm -rf {} +

get-new-packages:
	./build/get-new-packages

gc:
	nix-store --gc
	nix-env --delete-generations old

boot:
	nixos-rebuild --sudo boot --flake .#${HOSTNAME} -L

test:
	nixos-rebuild --sudo test --flake .#${HOSTNAME} -L

update:
	nix flake update

update-local:
	nix flake lock --update-input remarkable --update-input dcc

update-nflx:
	nix flake lock --update-input nflx --update-input nflx-vpn --update-input openconnect-pulse-launcher

update-secrets:
	nix flake lock --update-input secrets

upgrade:
	make update && make switch

clear-sddm-cache:
	sudo ./build/clear-sddm-cache

clear-mimeapps:
	[ -L "${HOME}/.config/mimeapps.list" ] || rm -f ${HOME}/.config/mimeapps.list
	# [ -L "${HOME}/.local/share/applications/mimeinfo.cache" ] || rm -f ${HOME}/.config/mimeapps.list

clear-gtkrc:
	# Plasma6 overwrites this, messing up the dark theme
	rm -f ${HOME}/.gtkrc-2.0


update-gnupg-perms:
	mkdir -p ${HOME}/.gnupg
	chmod 700 ${HOME}/.gnupg

update-nixpkgs:
	git submodule init
	git submodule update --remote nixpkgs
	cd nixpkgs; git config remote.upstream.url >&- || git remote add upstream https://github.com/NixOS/nixpkgs.git
	cd nixpkgs; git fetch upstream
	cd nixpkgs; git pull --rebase upstream master


