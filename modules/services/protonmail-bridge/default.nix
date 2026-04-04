# To get to cli:
#
#    systemctl --user stop protonmail-bridge
#    protonmail-bridge --cli
#
# To get password, in the cli, type "info"
#
{ pkgs, ... }:
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
  services.pass-secret-service.enable = true;
}
