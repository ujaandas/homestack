{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.caddy;
  context =
    if vmContext ? domain then
      vmContext
    else
      lib.attrByPath [ "homestack" "host" "hypervisor" "context" ] { } config;
  domain = lib.attrByPath [ "domain" ] (throw "caddy needs a domain in vmContext or homestack.host.hypervisor.context") context;
  contactEmail = lib.attrByPath [ "contact" "email" ] (
    throw "caddy needs contact.email in vmContext or homestack.host.hypervisor.context"
  ) context;
  caddyContext = lib.attrByPath [ "caddy" ] { } context;
  upstreams = {
    pocketid = lib.attrByPath [ "upstreams" "pocketid" ] (
      lib.attrByPath [ "vms" "auth" "ip" ] (
        throw "caddy needs caddy.upstreams.pocketid or vms.auth.ip in the active context"
      ) context
    ) caddyContext;

    netbird = lib.attrByPath [ "upstreams" "netbird" ] (
      lib.attrByPath [ "vms" "vpn" "ip" ] (
        throw "caddy needs caddy.upstreams.netbird or vms.vpn.ip in the active context"
      ) context
    ) caddyContext;
  };

  defaultVirtualHosts = {
    "*.${domain}".extraConfig = ''
      tls {
        dns cloudflare {file.{$CLOUDFLARE_API_KEY}}
      }
    '';

    "pocketid.${domain}".extraConfig = ''
      reverse_proxy ${upstreams.pocketid}
    '';

    "netbird.${domain}".extraConfig = ''
      reverse_proxy ${upstreams.netbird}
    '';
  };
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
      virtualHosts = defaultVirtualHosts // lib.attrByPath [ "virtualHosts" ] { } caddyContext;
    };

    systemd.services.caddy.serviceConfig = {
      LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
      Environment = [ ''CLOUDFLARE_API_KEY=%d/CLOUDFLARE_DNS_KEY'' ];
    };
  };
}
