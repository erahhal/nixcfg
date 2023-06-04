{ pkgs, ... }:
let
  node-modules = import ../../../pkgs/node-modules/default.nix { pkgs = pkgs; nodejs = pkgs.nodejs; };
in
{
  home.packages = [ 
    # node-modules.eslint
    # node-modules.prettier
    # node-modules.typescript
    # node-modules.typescript-language-server
    # node-modules.vscode-langservers-extracted

    # pkgs.nodePackages.eslint
    # pkgs.nodePackages.prettier
    # pkgs.nodePackages.typescript
    # pkgs.nodePackages.typescript-language-server
    # pkgs.unstable.nodePackages.vscode-langservers-extracted
  ];
}
