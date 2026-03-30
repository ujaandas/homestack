{
  lib,
  config,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.dnsmasq;
  domain = lib.attrByPath [ "domain" ] (throw "vmContext.domain is required for dnsmasq") vmContext;
  vmIps = lib.attrByPath [ "vms" ] (throw "vmContext.vms is required for dnsmasq") vmContext;
  proxyIp = lib.attrByPath [
    "proxy"
    "ip"
  ] (throw "vmContext.vms.proxy.ip is required for dnsmasq") vmIps;
in
{
  options.homestack.services.dnsmasq = {
    enable = lib.mkEnableOption "Enable Dnsmasq resolver for homestack.";
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        listen-address = proxyIp;
        bind-interfaces = true;
        server = [ "1.1.1.1" ];
        address = [
          "/pocketid.${domain}/${proxyIp}"
          "/netbird.${domain}/${proxyIp}"
        ];
      };
    };
  };
}
