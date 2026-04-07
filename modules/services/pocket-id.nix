{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.homestack.services.pocket-id;
in
{
  options.homestack.services.pocket-id = {
    enable = lib.mkEnableOption "Enable sane Pocket-ID service.";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain used for Pocket-ID public URL.";
    };

    authIp = lib.mkOption {
      type = lib.types.str;
      description = "IP address Pocket-ID should bind to inside the VM.";
    };

    dbIp = lib.mkOption {
      type = lib.types.str;
      description = "IP address of the PostgreSQL VM used by Pocket-ID.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://pocketid.${cfg.domain}";
        HOST = cfg.authIp;
        PORT = 3000;
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        DB_PROVIDER = "postgres";
        DB_CONNECTION_STRING = "postgresql://pocketid@${cfg.dbIp}:5432/pocketid";
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
