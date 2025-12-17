{ broken, pkgs, ... }:
{
  # network locator
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.printing.drivers = [
    pkgs.brlaser
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  hardware.printers = {
    ## Causes cupsd restart failures

    # ensureDefaultPrinter = "brother";
    # ensurePrinters = [
    #   {
    #     name = "brother";
    #     description = "Brother MFC-L2710DW";
    #     location = "Master Bedroom";
    #     # ipp:// seems to stop working a lot. Found out about using socket:// here:
    #     # https://askubuntu.com/questions/1411604/status-the-printer-may-not-exist-or-is-unavailable-at-this-time
    #     deviceUri = "socket://10.0.0.44:9100";
    #     # Found in /nix/store/...-brlaser-6/share/cups/drv/brlasrer.drv
    #     model = "drv:///brlaser.drv/brl2710.ppd";
    #   }
    # ];
  };

  ## @TODO: Re-enable when udev rules are fixed
  # hardware.sane = {
  #   enable = true;
  #   brscan5 = {
  #     enable = true;
  #     netDevices = {
  #       brother = {
  #         model = "MFC-L2710DW";
  #         nodename = "BRW8CC84B1E2FC1";
  #       };
  #     };
  #   };
  # };
}
