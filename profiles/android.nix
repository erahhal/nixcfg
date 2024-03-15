{ config, pkgs, inputs, system, userParams, ...}:
{
  users.users."${userParams.username}" = {
    extraGroups = [
      "adbusers"  # Android dev
    ];
  };

  services.udev = {
    packages = with pkgs; [
      android-udev-rules
    ];
  };

  programs.adb = {
    enable = true;
  };
}

