{ pkgs, userParams, ...}:
{
  environment.systemPackages = with pkgs; [
    android-tools
  ];

  users.users."${userParams.username}" = {
    extraGroups = [
      "adbusers"  # Android dev
    ];
  };
}

