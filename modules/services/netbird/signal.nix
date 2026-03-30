{
  lib,
  config,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.netbird;
  domain = lib.attrByPath [ "domain" ] (throw "vmContext.domain is required for netbird signal") vmContext;
  netbirdDomain = "netbird.${domain}";
in
{
  config = lib.mkIf (cfg.enable && cfg.roles.signal) {
    services.netbird.server.signal = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
    };

    systemd.services.netbird-signal.serviceConfig.Environment = [ "NB_PPROF_ADDR=6061" ];
  };
}
