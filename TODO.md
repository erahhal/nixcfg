TODOs
=====

## Functionality

* current build scripts in flake-parts/app.nix do a build follwed by a switch, because the switch command uses sudo -E. The reason for this is that some flake inputs are private and we want to make sure the user's ssh key is used, which doesn't work with root. can we just switch to using the --sudo flag with switch instead, no first build step?  Would it use the user's keys?
* Add first-class protonmail-bridge support if it is not already added.
  * if necessary update ~/Code/nixcfg-secrets
  * set this up with thunderbird
* Greeter config option
  * DMS Greeter vs SDDM vs new Plasma greeter
  * Is the new Plasma greeter the same as SDDM?
* Centralize all theming with light and dark modes. Look into the idiomatic way used by most people using Niri+DMS
* Backups
  * Get proper backup regime of home folder
  * Borg backups? what's the best right now? https://nixos.wiki/wiki/Borg_backup
* Get secure boot setup (lanzaboote?)
* Erase your darlings / Impermanence
  * https://grahamc.com/blog/erase-your-darlings/
  * https://nixos.wiki/wiki/Impermanence

## Bugs

* host antikythera hangs when several video windows open in firefox simultaneously
* Hibernation broken
  * criticalPowerAction = "Hibernate" doesn't seem to work
  * https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/8
* Can't use backspace when kmscon is enabled. VERASE is set to ctrl-h doesn't work in kmscon
  * See src/console/console-pty.c
