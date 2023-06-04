{ inputs, pkgs, system, userParams, ...}:
{
  imports =
    [
      ./xserver.nix
      ./sddm.nix
      ./lightdm.nix
      ./i3.nix
      ./sway.nix
      ./hyprland.nix
      ./fonts.nix
    ];

  # XDG portals - allow desktop apps to use resources outside their sandbox
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr # wlroots screen capture
      xdg-desktop-portal-gtk # gtk file dialogs
    ];
    # gtkUsePortal = true;
  };

  environment.systemPackages = with pkgs; [
    glxinfo
    inxi
    libcamera

    # inputs.nix-software-center.packages."${system}".nix-software-center
  ];

  home-manager.users.${userParams.username} = {
    imports = [
      ../home/profiles/i3status.nix
    ];
  };
}
