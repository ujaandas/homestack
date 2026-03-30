{
  lib,
  config,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.netbird;
  domain = lib.attrByPath [
    "domain"
  ] (throw "vmContext.domain is required for netbird dashboard") vmContext;
  netbirdDomain = "netbird.${domain}";
  pocketIdUrl = "https://pocketid.${domain}";
  clientId = lib.attrByPath [ "netbird" "clientId" ] "4716b464-7a15-4e06-aadd-b985650f2cba" vmContext;
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
        AUTH_CLIENT_ID = clientId;
        AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        AUTH_AUDIENCE = clientId;
        AUTH_REDIRECT_URI = "/auth";
        AUTH_SILENT_REDIRECT_URI = "/silent-auth";
        NETBIRD_TOKEN_SOURCE = "idToken";
      };
    };
  };
}
