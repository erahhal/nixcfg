{ ... }:
{
  # -------------------------------------------------------------
  # Host
  # -------------------------------------------------------------

  uid = 1000;
  gid = 100;

  hostName = "sicmundus";
  timeZone = "America/Los_Angeles";
  mainInterface = "enp4s0f0";
  containerBackend = "docker";
  defaultSession = "none";
  autoLogin = false;

  dpi = 96;
}

