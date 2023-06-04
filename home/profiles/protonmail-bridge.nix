# To get to cli:
#
#    systemctl --user stop protonmail-bridge
#    protonmail-bridge --cli
#
# To get password, in the cli, type "info"
#
# @TODO
#   - mv ~/.gnupg into ~/.local/share/gnupg and link to ~/.gnupg
#   - figure out how to store gnupg creds into nix config
#   - figure out how to store ~/.local/share/password-store into nix config
#     - might be fine as is, since it should already be encrypted
#   - Get code in scripts/setup-protonmail-bridge to use agenix or
#     otherwise use a mechanism that will store creds in nix config
#
{ pkgs, userParams, ... }:
{
  home.packages = with pkgs; [
    ## protonmail-bridge
    gnupg
    pass
    pinentry
  ];

  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry}/bin/pinentry
  '';

  programs.password-store.enable = true;
  services.pass-secret-service.enable = true;

  imports = [
    ../modules/protonmail-bridge.nix
  ];

  services.protonmail-bridge = {
    enable = true;
    nonInteractive = true;
  };
}
