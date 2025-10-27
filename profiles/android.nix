{ config, pkgs, inputs, system, userParams, ...}:
{
  users.users."${userParams.username}" = {
    extraGroups = [
      "adbusers"  # Android dev
    ];
  };

  programs.adb = {
    enable = true;
  };
}

