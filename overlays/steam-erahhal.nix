{ ... }:

let 
  erahhal = import <nixpkgs-erahhal> {};
in
  let steamErahhalOverlay = self: super: {
    nixpkgs = super.nixpkgs or {} // {
      steam = erahhal.steamPackages.steam-fhsenv;
    };
  };
in
{
  nixpkgs.overlays = [ steamErahhalOverlay ];
}
