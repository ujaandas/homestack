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
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://pocketid.ujaan.me";
        HOST = "192.168.100.3";
        PORT = 3000;
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        DB_PROVIDER = "postgres";
        DB_CONNECTION = "postgresql://pocketid@192.168.100.2:5432/pocketid";
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
