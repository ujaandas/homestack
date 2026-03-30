{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.netbird;
  domain = lib.attrByPath [ "domain" ] (throw "vmContext.domain is required for netbird management") vmContext;
  pocketIdUrl = "https://pocketid.${domain}";
  netbirdDomain = "netbird.${domain}";
  clientId = lib.attrByPath [ "netbird" "clientId" ] "4716b464-7a15-4e06-aadd-b985650f2cba" vmContext;
in
{
  config = lib.mkIf (cfg.enable && cfg.roles.management) {
    services.netbird.server.management = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      disableAnonymousMetrics = true;
      oidcConfigEndpoint = "${pocketIdUrl}/.well-known/openid-configuration";

      settings = {
        Signal.URI = "${netbirdDomain}:443";

        HttpConfig = {
          AuthAudience = clientId;
          IdpSignKeyRefreshEnabled = true;
        };

        DeviceAuthorizationFlow = {
          Provider = "none";
          ProviderConfig = {
            ClientID = "netbird";
            Audience = "netbird";
            Scope = "openid profile email groups";
            UseIDToken = true;
          };
        };

        IdpManagerConfig = {
          ManagerType = "pocketid";
          ClientConfig = {
            ClientID = "netbird";
          };

          ExtraConfig = {
            ManagementEndpoint = pocketIdUrl;
            ApiToken = "";
          };
        };

        PKCEAuthorizationFlow.ProviderConfig = {
          Audience = clientId;
          ClientID = clientId;
        };

        TURNConfig = {
          Secret._secret = "/run/credentials/netbird-management.service/TURN_KEY";
          CredentialsTTL = "12h";
          TimeBasedCredentials = false;
          Turns = [
            {
              Password._secret = "/run/credentials/netbird-management.service/TURN_KEY";
              Proto = "udp";
              URI = "turn:${netbirdDomain}:3478";
              Username = "netbird";
            }
          ];
        };

        Relay = {
          Addresses = [ "rels://${netbirdDomain}:33080" ];
          CredentialsTTL = "24h";
          Secret._secret = "/run/credentials/netbird-management.service/RELAY_KEY";
        };

        DataStoreEncryptionKey._secret = "/run/credentials/netbird-management.service/DATA_STORE_ENC_KEY";
      };
    };

    systemd.services.netbird-management = {
      serviceConfig = {
        LoadCredential = [
          "TURN_KEY"
          "DATA_STORE_ENC_KEY"
          "RELAY_KEY"
          "POCKETID_API_KEY"
        ];

        Environment = ''
          NETBIRD_DOMAIN="${netbirdDomain}"
          NETBIRD_DISABLE_LETSENCRYPT=true
          NETBIRD_MGMT_API_PORT=443
          NETBIRD_SIGNAL_PORT=443
          TURN_MIN_PORT=40000
          TURN_MAX_PORT=40050
        '';
      };

      preStart = lib.mkAfter ''
        API_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/POCKETID_API_KEY")

        ${pkgs.jq}/bin/jq --arg token "$API_TOKEN" \
          '.IdpManagerConfig.ExtraConfig.ApiToken = $token' \
          /var/lib/netbird-mgmt/management.json > /var/lib/netbird-mgmt/management.json.tmp

        mv /var/lib/netbird-mgmt/management.json.tmp /var/lib/netbird-mgmt/management.json
      '';
    };
  };
}
