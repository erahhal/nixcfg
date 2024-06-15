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
NOM := nom

switch: 
	# make clear-sddm-cache
	make clear-mimeapps
	make clear-gpu-cache
	# nixos-rebuild --log-format internal-json -v --use-remote-sudo switch --flake .#${HOSTNAME} -L |& ${NOM} --json
	nixos-rebuild --use-remote-sudo switch --flake .#${HOSTNAME} -L
	make update-gnupg-perms
	# Building defaults to dark, so switch back if it was light before
	NEW_THEME=$$(cat ~/.system-theme) ;\
	if [ "$(CURR_THEME)" != "$$NEW_THEME" ]; then \
		systemctl --user restart toggle-theme ;\
	fi

show-trace:
	make clear-sddm-cache
	make clear-mimeapps
	# nixos-rebuild --log-format internal-json -v --use-remote-sudo switch --show-trace --flake .#${HOSTNAME} -L |& ${NOM} --json
	nixos-rebuild --use-remote-sudo switch --show-trace --flake .#${HOSTNAME} -L
	make update-gnupg-perms

offline:
	# nixos-rebuild --log-format internal-json -v --use-remote-sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L |& ${NOM} --json
	nixos-rebuild -v --use-remote-sudo switch --offline --option binary-caches "" --flake .#${HOSTNAME} -L

clear-gpu-cache:
	mkdir -p ~/.config
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
	nix flake lock --update-input nflx --update-input nflx-vpn --update-input openconnect-pulse-launcher

upgrade:
	make update && make switch

clear-sddm-cache:
	sudo ./build/clear-sddm-cache

clear-mimeapps:
	[ -L "${HOME}/.config/mimeapps.list" ] || rm -f ${HOME}/.config/mimeapps.list
	[ -L "${HOME}/.local/share/mimeinfo.cache" ] || rm -f ${HOME}/.local/share/mimeinfo.cache

update-gnupg-perms:
	mkdir -p ${HOME}/.gnupg
	chmod 700 ${HOME}/.gnupg

update-nixpkgs:
	git submodule init
	git submodule update --remote nixpkgs
	cd nixpkgs; git config remote.upstream.url >&- || git remote add upstream https://github.com/NixOS/nixpkgs.git
	cd nixpkgs; git fetch upstream
	cd nixpkgs; git pull --rebase upstream master


