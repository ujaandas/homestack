{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.caddy;
  domain = vmContext.domain or "ujaan.me";
  vmIps = vmContext.vms or { };
  authIp = if builtins.hasAttr "auth" vmIps then vmIps.auth.ip else "192.168.100.3";
  vpnIp = if builtins.hasAttr "vpn" vmIps then vmIps.vpn.ip else "192.168.100.5";
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
      email = "ujaandas03@gmail.com";
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
