{
  lib,
  config,
  ...
}:
let
  cfg = config.homestack.services.netbird;
in
{
  config = lib.mkIf (cfg.enable && cfg.roles.coturn) {
    services.netbird.server.coturn = {
      enable = true;
      useAcmeCertificates = true;
      passwordFile = "/run/credentials/coturn.service/TURN_KEY";
    };

    systemd.services.coturn.serviceConfig.LoadCredential = [ "TURN_KEY" ];
  };
}
