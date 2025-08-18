{ lib, ... }:

{
  home.activation.updateGitConfig = lib.hm.dag.entryAfter [ "installPackages" ] ''
      CONFIG_FILE="$HOME/.ssh/config"
      touch $CONFIG_FILE
      # A unique marker that identifies our extra configuration.
      MARKER="## Extra Git config from Nix home-manager"

      if ! grep -q "''${MARKER}" "$CONFIG_FILE" 2>/dev/null; then
          echo "Appending extra configuration to \$CONFIG_FILE"
          cat <<EOF >> "$CONFIG_FILE"
      ''${MARKER}
      Host erahhal-github
          HostName github.com
          User git
          IdentityFile ~/.ssh/id_rsa
      Host turingtesttwister-github
          HostName github.com
          User git
          IdentityFile ~/.ssh/id_rsa_turing_test_twister
      EOF
      else
          echo "Extra configuration already present in \$CONFIG_FILE"
      fi
    '';
}
