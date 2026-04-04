{ pkgs, userParams, ... }:

{
  users.groups.i2c = {};
  users.users."${userParams.username}".extraGroups = [ "i2c" ];

  # Load the i2c-dev module
  boot.kernelModules = [ "i2c_dev" "ddcci_backlight" ];

  # Create the udev rules for i2c access
  services.udev.extraRules = ''
    # Give members of i2c group access to i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    SUBSYSTEM=="i2c-dev", ACTION=="add",\
    ATTR{name}=="NVIDIA i2c adapter*",\
    TAG+="ddcci",\
    TAG+="systemd",\
    ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
  '';

  systemd.services."ddcci@" = {
    scriptArgs = "%i";
    script = ''
    echo Trying to attach ddcci to $1
    i=0
    id=$(echo $1 | cut -d "-" -f 2)
    if ${pkgs.ddcutil}/bin/ddcutil getvcp 10 -b $id; then
    echo ddcci 0x37 > /sys/bus/i2c/devices/$1/new_device
    fi
    '';
    serviceConfig.Type = "oneshot";
  };

  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
  ];

  ## @BROKEN
  ## Includes "i2c-dev" kernel module and ddccontrol util
  # services.ddccontrol.enable = true;

  # Optional: Set suid bit on ddcutil
  # (Only uncomment if the group-based approach doesn't work)
  # security.wrappers.ddcutil = {
  #   source = "${pkgs.ddcutil}/bin/ddcutil";
  #   owner = "root";
  #   group = "root";
  #   capabilities = "cap_sys_admin+ep";
  # };
}
