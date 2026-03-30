{
  lib,
  config,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.dnsmasq;
  domain = vmContext.domain or "ujaan.me";
  vmIps = vmContext.vms or { };
  proxyIp = if builtins.hasAttr "proxy" vmIps then vmIps.proxy.ip else "192.168.100.4";
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
