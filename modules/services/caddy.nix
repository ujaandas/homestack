{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.caddy;
  domain = lib.attrByPath [ "domain" ] (throw "vmContext.domain is required for caddy") vmContext;
  vmIps = lib.attrByPath [ "vms" ] (throw "vmContext.vms is required for caddy") vmContext;
  authIp = lib.attrByPath [ "auth" "ip" ] (throw "vmContext.vms.auth.ip is required for caddy") vmIps;
  vpnIp = lib.attrByPath [ "vpn" "ip" ] (throw "vmContext.vms.vpn.ip is required for caddy") vmIps;
  contactEmail = lib.attrByPath [ "contact" "email" ] "ujaandas03@gmail.com" vmContext;
in
{
  options.homestack.services.caddy = {
    enable = lib.mkEnableOption "Enable Caddy reverse proxy for homestack.";
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
        hash = "sha256-ea8PC/+SlPRdEVVF/I3c1CBprlVp1nrumKM5cMwJJ3U=";
      };
      email = contactEmail;
      globalConfig = ''
        admin off
      '';
      virtualHosts = {
        "*.${domain}".extraConfig = ''
          tls {
            dns cloudflare {file.{$CLOUDFLARE_API_KEY}}
          }
        '';

        "pocketid.${domain}".extraConfig = ''
          reverse_proxy ${authIp}:3000
        '';

        "netbird.${domain}".extraConfig = ''
          reverse_proxy ${vpnIp}
        '';
      };
    };

    systemd.services.caddy.serviceConfig = {
      LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
      Environment = [ ''CLOUDFLARE_API_KEY=%d/CLOUDFLARE_DNS_KEY'' ];
    };
  };
}
