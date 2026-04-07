{
  lib,
  config,
  ...
}:
let
  cfg = config.homestack.services.dnsmasq;
in
{
  options.homestack.services.dnsmasq = {
    enable = lib.mkEnableOption "Enable Dnsmasq resolver for homestack.";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain used for homestack DNS records.";
    };

    proxyIp = lib.mkOption {
      type = lib.types.str;
      description = "IP address to answer for homestack DNS records.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        listen-address = cfg.proxyIp;
        bind-interfaces = true;
        server = [ "1.1.1.1" ];
        address = [
          "/pocketid.${cfg.domain}/${cfg.proxyIp}"
          "/netbird.${cfg.domain}/${cfg.proxyIp}"
        ];
      };
    };
  };
}
