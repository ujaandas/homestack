{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.homestack.services.caddy;
  domain = "ujaan.me";
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
          reverse_proxy 192.168.100.3:3000
        '';

        "netbird.${domain}".extraConfig = ''
          reverse_proxy 192.168.100.5
        '';
      };
    };

    systemd.services.caddy.serviceConfig = {
      LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
      Environment = [ ''CLOUDFLARE_API_KEY=%d/CLOUDFLARE_DNS_KEY'' ];
    };
  };
}
