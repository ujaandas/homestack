{
  lib,
  config,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.netbird;
  domain = lib.attrByPath [ "domain" ] (throw "vmContext.domain is required for netbird") vmContext;
  vmIps = lib.attrByPath [ "vms" ] (throw "vmContext.vms is required for netbird") vmContext;
  proxyIp = lib.attrByPath [
    "proxy"
    "ip"
  ] (throw "vmContext.vms.proxy.ip is required for netbird") vmIps;
  contactEmail = lib.attrByPath [ "contact" "email" ] "ujaandas03@gmail.com" vmContext;
  netbirdDomain = "netbird.${domain}";
in
{
  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${netbirdDomain}".locations."/".tryFiles = lib.mkForce "$uri $uri/ /index.html";

      netbird.server = {
        enable = true;
        enableNginx = true;
        domain = netbirdDomain;
      };

      resolved = {
        enable = true;
        dnssec = "allow-downgrade";
        fallbackDns = [ ];
        domains = [ "~." ];
      };
    };

    nixpkgs.overlays = [
      (final: prev: {
        netbird = prev.netbird.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "ujaandas";
            repo = "netbird";
            rev = "6e4d3554917dae507bd000952f6b88a167d1a093";
            sha256 = "sha256-Q7lfXHQYr0qdT/gAOei4YF0ojwPfmN4Rp8J3zZwv938=";
          };
          vendorHash = "sha256-b3Wl9jsAdYC91JM/kDo4yIF05hqbivtrcn1aRuZzP3s=";
        });
      })
    ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = contactEmail;
        dnsResolver = proxyIp;
      };
      certs."${netbirdDomain}" = {
        dnsProvider = "cloudflare";
      };
    };

    systemd.services."acme-order-renew-${netbirdDomain}".serviceConfig = {
      LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
      Environment = [ ''CLOUDFLARE_DNS_API_TOKEN_FILE=%d/CLOUDFLARE_DNS_KEY'' ];
    };

    fileSystems."/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=1G" ];
    };

    networking = {
      nameservers = [ proxyIp ];
      useHostResolvConf = false;
    };
  };
}
