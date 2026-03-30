{
  lib,
  config,
  pkgs,
  vmContext ? { },
  ...
}:
let
  cfg = config.homestack.services.netbird;
  domain = vmContext.domain or "ujaan.me";
  vmIps = vmContext.vms or { };
  proxyIp = if builtins.hasAttr "proxy" vmIps then vmIps.proxy.ip else "192.168.100.4";
  pocketIdUrl = "https://pocketid.${domain}";
  netbirdDomain = "netbird.${domain}";
  clientId = "4716b464-7a15-4e06-aadd-b985650f2cba";
in
{
  options.homestack.services.netbird = {
    enable = lib.mkEnableOption "Enable NetBird self-hosted VPN stack.";
  };

  config = lib.mkIf cfg.enable {
    services = {

      nginx.virtualHosts."${netbirdDomain}".locations."/".tryFiles = lib.mkForce "$uri $uri/ /index.html";

      netbird.server = {
        enable = true;
        enableNginx = true;
        domain = netbirdDomain;

        coturn = {
          enable = true;
          useAcmeCertificates = true;
          passwordFile = "/run/credentials/coturn.service/TURN_KEY";
        };

        dashboard = {
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

        management = {
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

        signal = {
          enable = true;
          enableNginx = true;
          domain = netbirdDomain;
        };
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
          vendorSha256 = "";
        });
      })
    ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "ujaandas03@gmail.com";
        dnsResolver = proxyIp;
      };
      certs."${netbirdDomain}" = {
        dnsProvider = "cloudflare";
      };
    };

    systemd.services = {
      coturn.serviceConfig.LoadCredential = [ "TURN_KEY" ];

      netbird-management = {
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

      "acme-order-renew-${netbirdDomain}".serviceConfig = {
        LoadCredential = [ "CLOUDFLARE_DNS_KEY" ];
        Environment = [ ''CLOUDFLARE_DNS_API_TOKEN_FILE=%d/CLOUDFLARE_DNS_KEY'' ];
      };

      netbird-signal.serviceConfig.Environment = [ "NB_PPROF_ADDR=6061" ];
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
