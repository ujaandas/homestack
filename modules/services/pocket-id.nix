{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.pocket-id;
  domain = vmContext.domain or "ujaan.me";
  vmIps = vmContext.vms or { };
  authIp = if builtins.hasAttr "auth" vmIps then vmIps.auth.ip else "192.168.100.3";
  dbIp = if builtins.hasAttr "db" vmIps then vmIps.db.ip else "192.168.100.2";
in
{
  options.homestack.services.pocket-id = {
    enable = lib.mkEnableOption "Enable sane Pocket-ID service.";
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://pocketid.${domain}";
        HOST = authIp;
        PORT = 3000;
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        DB_PROVIDER = "postgres";
        DB_CONNECTION_STRING = "postgresql://pocketid@${dbIp}:5432/pocketid";
        KEYS_STORAGE = "database";
      };
    };

    systemd = {
      services.pocket-id.serviceConfig = {
        LoadCredential = [ "POCKETID_ENC_KEY" ];
        Environment = [ ''ENCRYPTION_KEY_FILE=%d/POCKETID_ENC_KEY'' ];
      };
      tmpfiles.rules = [ "d /var/lib/pocket-id 0755 pocket-id pocket-id -" ];
    };
  };
}
