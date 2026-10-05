# Sends this machine's audio to the house speakers (the mediaserver fleet the
# HomeFree box runs) as a stream of its own. Pick the "House speakers" output,
# then play the stream from the mediaserver console (Play everywhere, or per
# speaker). A small sender keeps the stream registered on the box's
# snapserver through restarts, roaming and address changes. The server needs
# no entry for this machine, so any laptop running this works, and its
# stream goes away with it.
#
# Replaces a local snapserver fed by a PipeWire pipe tunnel, which the house
# had to know about by address.
{ config, lib, inputs, ... }:
let
  cfg = config.nixcfg.services.mediaserver-sender;
  params = config.hostParams.desktop.mediaserverSender;
in {
  imports = [ inputs.mediaserver.nixosModules.sender ];

  options.nixcfg.services.mediaserver-sender = {
    enable = lib.mkEnableOption "sending this machine's audio to the house speakers";
  };

  config = lib.mkIf cfg.enable {
    services.mediaserver-sender = {
      enable = true;
      inherit (params) serverHost serverAddress;
    };
  };
}
