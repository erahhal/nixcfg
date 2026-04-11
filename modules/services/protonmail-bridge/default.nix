# To get to cli:
#
#    systemctl --user stop protonmail-bridge
#    protonmail-bridge --cli
#
# To get password, in the cli, type "info"
#
{ pkgs, osConfig, lib, ... }:
let
  userParams = osConfig.hostParams.user;
in
{
  # Uses the official home-manager services.protonmail-bridge module
  services.protonmail-bridge.enable = true;

  # GPG and pass needed for protonmail-bridge credential storage
  home.packages = with pkgs; [
    gnupg
    pass
    pinentry-curses
  ];

  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
  '';

  programs.password-store.enable = true;

  home.activation.protonmailBridgeGpg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PROTONMAIL_EMAIL="${userParams.protonmailEmail}"
    FULL_NAME="${userParams.fullName}"

    if [ -n "$PROTONMAIL_EMAIL" ]; then
      # Check if a GPG key matching the protonmail email exists
      KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons "$PROTONMAIL_EMAIL" 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^pub' | head -1 | cut -d: -f5)

      if [ -z "$KEY_ID" ]; then
        echo "No GPG key found for $PROTONMAIL_EMAIL. Generating one for protonmail-bridge..."
        ${pkgs.gnupg}/bin/gpg --batch --gen-key <<GPGEOF
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: $FULL_NAME
Name-Comment: protonmail-bridge
Name-Email: $PROTONMAIL_EMAIL
Expire-Date: 0
%no-protection
%commit
GPGEOF
        echo "GPG key generated."
        KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons "$PROTONMAIL_EMAIL" 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^pub' | head -1 | cut -d: -f5)
      fi

      # Initialize or fix pass if .gpg-id is missing or points to a wrong/unusable key
      NEEDS_INIT=0
      if [ ! -f "$HOME/.password-store/.gpg-id" ]; then
        NEEDS_INIT=1
      else
        CURRENT_KEY=$(cat "$HOME/.password-store/.gpg-id")
        if ! ${pkgs.gnupg}/bin/gpg --list-keys --with-colons "$CURRENT_KEY" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q '^pub'; then
          echo "pass is configured with unusable key $CURRENT_KEY. Reinitializing..."
          NEEDS_INIT=1
        fi
      fi

      if [ "$NEEDS_INIT" -eq 1 ] && [ -n "$KEY_ID" ]; then
        echo "Initializing pass with GPG key $KEY_ID..."
        ${pkgs.pass}/bin/pass init "$KEY_ID"
        echo "pass initialized."
      fi
    fi
  '';
}
