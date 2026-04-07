{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.homestack.services.caddy;
  proxyVirtualHosts = lib.mapAttrs' (
    name: upstream:
    lib.nameValuePair "${name}.${cfg.domain}" {
      extraConfig = ''
        reverse_proxy ${upstream}
      '';
    }
  ) cfg.upstreams;
in
{
  options.homestack.services.caddy = {
    enable = lib.mkEnableOption "Enable Caddy reverse proxy for homestack.";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain used to generate Caddy virtual hosts.";
    };

    contactEmail = lib.mkOption {
      type = lib.types.str;
      description = "Contact email used by Caddy/ACME.";
    };

    upstreams = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        pocketid = "192.168.100.3:3000";
        netbird = "192.168.100.5:443";
      };
      description = "Named upstreams in host:port format; each key becomes <name>.<domain>.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
        hash = "sha256-ea8PC/+SlPRdEVVF/I3c1CBprlVp1nrumKM5cMwJJ3U=";
      };
      email = cfg.contactEmail;
      globalConfig = ''
        admin off
      '';
      virtualHosts = {
        "*.${cfg.domain}".extraConfig = ''
          tls {
            dns cloudflare {file.{$CLOUDFLARE_API_KEY}}
          }
        '';
      }
      // proxyVirtualHosts;
    };

    systemd.services.caddy.serviceConfig = {
      LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
      Environment = [ ''CLOUDFLARE_API_KEY=%d/CLOUDFLARE_DNS_KEY'' ];
    };
  };
}
