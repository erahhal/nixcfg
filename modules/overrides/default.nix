{ config, system, ...}:

let
  nixpkgs-tars = "https://github.com/NixOS/nixpkgs/archive/";
in {
  nixpkgs.config = {

    # How to install from pull requests:
    # https://dumpstack.io/1563582225_nixos_installing_software_from_pull_requests.html
    #
    # To get commit hash:
    # curl -sL https://github.com/NixOS/nixpkgs/pull/67576.patch | head -n 1 | grep -o -E -e "[0-9a-f]{40}"

    packageOverrides = pkgs: {

      # https://github.com/NixOS/nixpkgs/pull/67576
      # Install using the package: pr67576-gimp-wayland.gimp-with-plugins
      pr67576-gimp-wayland = import (fetchTarball {
        ## Fails to build
        # url = "${nixpkgs-tars}3104b3c0ac170cdce3e7279f2f65ffee357c95de.tar.gz";
        # sha256 = "1ilmxbm5hbqz63d3xyd267an7bbsqzcwb8krcjs1mxjsjicr7by1";

        ## Fails to build gimp-with-plugins
        ## WORKS with gimp
        ## Seems to be the only commit that works
        url = "${nixpkgs-tars}86947c8f83a3bd593eefb8e5f433f0d045c3d9a7.tar.gz";
        sha256 = "1lc63hs87nclb2ikn8d67ihm4pd6kcls3pybmkr0im91vprbywff";

        ## Head isn't even beta version
        # url = "${nixpkgs-tars}3104b3c0ac170cdce3e7279f2f65ffee357c95de.tar.gz";
        # sha256 = "1ilmxbm5hbqz63d3xyd267an7bbsqzcwb8krcjs1mxjsjicr7by1";

        ## Fails to build
        # url = "${nixpkgs-tars}3ae54d7e237c146367ff258967442d7297eb9691.tar.gz";
        # sha256 = "1sn9y6pxrs8r2srwy10ndqk0fy7p4z64fmxm7r4zffhscilg40y5";

        ## Fails to build
        # url = "${nixpkgs-tars}6c272e79ea31e77105cc0ba0e972cb6925f9cec9.tar.gz";
        # sha256 = "0p5ksq24l7ccrxcg2ikv7v32kr16c8gfpgbx3y4hl2df457zhki5";

        ## Fails to build
        # url = "${nixpkgs-tars}88dd47501754d2cb95a95dbff7d2c7ff28fe6e03.tar.gz";
        # sha256 = "0wzdhxis2biyhp91xrspmh2z1dnlf44k0bnvqd8lcy3ppc7wz2sa";
      }) {
        config = config.nixpkgs.config;
        inherit system;
      };

    };
  };
}
