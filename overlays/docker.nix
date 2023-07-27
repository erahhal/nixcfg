{ pkgs, ... }:
{
  # pin docker to older nixpkgs: https://github.com/NixOS/nixpkgs/issues/244159
  nixpkgs.overlays = [
    (final: prev: {
      docker = pkgs.unstable.docker;
    })

    ## Older version of docker
    # (let
    #   pinnedPkgs = import(pkgs.fetchFromGitHub {
    #     owner = "NixOS";
    #     repo = "nixpkgs";
    #     rev = "b6bbc53029a31f788ffed9ea2d459f0bb0f0fbfc";
    #     sha256 = "sha256-JVFoTY3rs1uDHbh0llRb1BcTNx26fGSLSiPmjojT+KY=";
    #   }) {};
    # in
    # final: prev: {
    #   docker = pinnedPkgs.docker;
    # })
  ];
}
