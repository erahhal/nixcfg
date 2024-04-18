{ pkgs, userParams, ...}:
{
  imports =
    [
      ./xserver.nix
      ./sddm.nix
      ./lightdm.nix
      ./i3.nix
      ./wayland-window-manager.nix
      ./sway.nix
      ./hyprland.nix
      ./fonts.nix
    ];

  environment.systemPackages = with pkgs; [
    glxinfo
    inxi
    libcamera

    # inputs.nix-software-center.packages."${system}".nix-software-center
  ];
}
