{ pkgs, userParams, ... }:

{
  users.groups.i2c = {};
  users.users."${userParams.username}".extraGroups = [ "i2c" ];

  # Create the udev rules for i2c access
  services.udev.extraRules = ''
    # Give members of i2c group access to i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
  ];

  ## Includes "i2c-dev" kernel module and ddccontrol util
  services.ddccontrol.enable = true;

  # Optional: Set suid bit on ddcutil
  # (Only uncomment if the group-based approach doesn't work)
  # security.wrappers.ddcutil = {
  #   source = "${pkgs.ddcutil}/bin/ddcutil";
  #   owner = "root";
  #   group = "root";
  #   capabilities = "cap_sys_admin+ep";
  # };
}
