final: prev: {
  hyprland-patched = prev.hyprland.overrideAttrs (finalAttrs: oldAttrs: {
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = oldAttrs.pname;
      fetchSubmodules = true;
      rev = "118d4e1001d5847aa42d1e5d5fa9623954ae751d";
      hash = "sha256-1oVVblacE6uQztHTdPG6NoUzj5RErIebmDoVNWnG6xg=";
    };
  });

  hyprwayland-scanner = prev.hyprwayland-scanner.overrideAttrs (finalAttrs: oldAttrs: {
    version = "a048a6cb015340bd82f97c1f40a4b595ca85cc30";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprwayland-scanner";
      rev = "a048a6cb015340bd82f97c1f40a4b595ca85cc30";
      hash = "sha256-SOOqIT27/X792+vsLSeFdrNTF+OSRp5qXv6Te+fb2Qg=";
    };
  });

  hyprland-protocols = prev.hyprland-protocols.overrideAttrs (finalAttrs: oldAttrs: {
    version = "5a11232266bf1a1f5952d5b179c3f4b2facaaa84";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprland-protocols";
      rev = "5a11232266bf1a1f5952d5b179c3f4b2facaaa84";
      hash = "sha256-zCu4R0CSHEactW9JqYki26gy8h9f6rHmSwj4XJmlHgg=";
    };
  });

  hyprlang = prev.hyprlang.overrideAttrs (finalAttrs: oldAttrs: {
    version = "adbefbf49664a6c2c8bf36b6487fd31e3eb68086";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprlang";
      rev = "adbefbf49664a6c2c8bf36b6487fd31e3eb68086";
      hash = "sha256-BiJKO0IIdnSwHQBSrEJlKlFr753urkLE48wtt0UhNG4=";
    };
  });

  hyprcursor = prev.hyprcursor.overrideAttrs (finalAttrs: oldAttrs: {
    version = "4493a972b48f9c3014befbbf381ed5fff91a65dc";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprcursor";
      rev = "4493a972b48f9c3014befbbf381ed5fff91a65dc";
      hash = "sha256-aYlHTWylczLt6ERJyg6E66Y/XSCbVL7leVcRuJmVbpI=";
    };
  });

  hyprutils = prev.hyprutils.overrideAttrs (finalAttrs: oldAttrs: {
    version = "5dcbbc1e3de40b2cecfd2007434d86e924468f1f";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprutils";
      rev = "5dcbbc1e3de40b2cecfd2007434d86e924468f1f";
      hash = "sha256-D3wIZlBNh7LuZ0NaoCpY/Pvu+xHxIVtSN+KkWZYvvVs=";
    };
  });

  xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (finalAttrs: oldAttrs: {
    version = "7f2a77ddf60390248e2a3de2261d7102a13e5341";
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "xdg-desktop-portal-hyprland";
      rev = "7f2a77ddf60390248e2a3de2261d7102a13e5341";
      hash = "sha256-Khdm+mDzYA//XaU0M+hftod+rKr5q9SSHSEuiQ0/9ow=";
    };
  });
}
