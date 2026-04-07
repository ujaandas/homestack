{
  lib,
  config,
  ...
}:
let
  cfg = config.homestack.services.netbird;
  netbirdDomain = "netbird.${cfg.domain}";
  pocketIdUrl = "https://pocketid.${cfg.domain}";
in
{
  config = lib.mkIf (cfg.enable && cfg.roles.dashboard) {
    services.netbird.server.dashboard = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      settings = {
        AUTH_AUTHORITY = pocketIdUrl;
        USE_AUTH0 = false;
        AUTH_CLIENT_ID = cfg.clientId;
        AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        AUTH_AUDIENCE = cfg.clientId;
        AUTH_REDIRECT_URI = "/auth";
        AUTH_SILENT_REDIRECT_URI = "/silent-auth";
        NETBIRD_TOKEN_SOURCE = "idToken";
      };
    };
  };
}
