{
  lib,
  config,
  ...
}:
let
  cfg = config.homestack.services.dnsmasq;
  domain = "ujaan.me";
in
{
  options.homestack.services.dnsmasq = {
    enable = lib.mkEnableOption "Enable Dnsmasq resolver for homestack.";
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        listen-address = "192.168.100.4";
        bind-interfaces = true;
        server = [ "1.1.1.1" ];
        address = [
          "/pocketid.${domain}/192.168.100.4"
          "/netbird.${domain}/192.168.100.4"
        ];
      };
    };
  };
}
