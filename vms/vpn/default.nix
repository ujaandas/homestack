{
  config,
  lib,
  pkgs,
  coturnSecretPath,
  netbirdSecretPath,
  ...
}:
let
  domain = "ujaan.me";
  clientId = "f6265027-af5e-47b8-a5a8-97e076688d88";
in
{
  imports = [
    ./microvm-configuration.nix
  ];

  services = {
    openssh.enable = true;

    nginx.virtualHosts."netbird.${domain}".locations."/" = {
      tryFiles = lib.mkForce "$uri $uri/ /index.html";
    };

    # very confusingly, things from setup.env are split between modules with odd names,
    # so i've tried my best to match them up from https://docs.netbird.io/selfhosted/identity-providers/pocketid
    # also check options from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/netbird/management.nix
    # against https://github.com/netbirdio/netbird/blob/main/infrastructure_files/management.json.tmpl
    netbird = {
      server = {
        enable = true;
        enableNginx = true;
        domain = "netbird.${domain}";

        coturn = {
          enable = true;
          useAcmeCertificates = true;
          # passwordFile = "%d/COTURN";
          password = "shitbag";
        };

        dashboard = {
          enable = true;
          enableNginx = true;
          domain = "netbird.${domain}";
          settings = {
            AUTH_AUTHORITY = "https://pocketid.${domain}";
            USE_AUTH0 = false; # NETBIRD_USE_AUTH0
            AUTH_CLIENT_ID = clientId; # NETBIRD_AUTH_CLIENT_ID
            AUTH_SUPPORTED_SCOPES = "openid profile email groups"; # NETBIRD_AUTH_SUPPORTED_SCOPES
            AUTH_AUDIENCE = clientId; # NETBIRD_AUTH_AUDIENCE
            AUTH_REDIRECT_URI = "/auth"; # NETBIRD_AUTH_REDIRECT_URI
            AUTH_SILENT_REDIRECT_URI = "/silent-auth"; # NETBIRD_AUTH_SILENT_REDIRECT_URI
            NETBIRD_TOKEN_SOURCE = "idToken"; # NETBIRD_TOKEN_SOURCE
          };
        };

        management = {
          enable = true;
          enableNginx = true;
          domain = "netbird.${domain}";
          disableAnonymousMetrics = true;
          oidcConfigEndpoint = "https://pocketid.${domain}/.well-known/openid-configuration"; # NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT

          # we're basically building the management.json here, so the netbird docs won't line up - you need to cross-check with management.json.tmpl
          settings = {
            Signal.URI = "netbird.${domain}:443";

            HttpConfig = {
              AuthAudience = clientId; # NETBIRD_AUTH_AUDIENCE
              IdpSignKeyRefreshEnabled = true; # NETBIRD_MGMT_IDP_SIGNKEY_REFRESH
            };

            DeviceAuthorizationFlow = {
              Provider = "none"; # NETBIRD_AUTH_DEVICE_AUTH_PROVIDER
              ProviderConfig = {
                ClientID = "netbird"; # NETBIRD_AUTH_DEVICE_AUTH_CLIENT_ID
                Audience = "netbird"; # NETBIRD_AUTH_DEVICE_AUTH_AUDIENCE
                Scope = "openid profile email groups"; # NETBIRD_AUTH_DEVICE_AUTH_SCOPE
                UseIDToken = true; # NETBIRD_AUTH_DEVICE_AUTH_USE_ID_TOKEN
              };
            };

            IdpManagerConfig = {
              ManagerType = "pocketid"; # NETBIRD_MGMT_IDP
              ClientConfig = {
                ClientID = "netbird"; # NETBIRD_IDP_MGMT_CLIENT_ID
              };

              ExtraConfig = {
                # found these in source code: config.ExtraConfig["ApiToken"]
                ManagementEndpoint = "https://pocketid.ujaan.me"; # NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT
                ApiToken = "awsQisTYYrEin7Klp8CWRr4X7TvODYV0"; # NETBIRD_IDP_MGMT_EXTRA_API_TOKEN
              };
            };

            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = clientId;
              ClientID = clientId;
            };

            TURNConfig = {
              Secret = "EjiKJTChL55T09m/KXWAugEFiszwCaND6YhmCSCeWcM=";
              CredentialsTTL = "12h";
              TimeBasedCredentials = false;
              Turns = [
                {
                  Password = "EjiKJTChL55T09m/KXWAugEFiszwCaND6YhmCSCeWcM=";
                  Proto = "udp";
                  URI = "turn:netbird.${domain}:3478";
                  Username = "netbird";
                }
              ];
            };

            Relay = {
              Addresses = [ "rels://netbird.${domain}:33080" ];
              CredentialsTTL = "24h";
              Secret = "EjiKJTChL55T09m/KXWAugEFiszwCaND6YhmCSCeWcM=";
            };

            DataStoreEncryptionKey = "EjiKJTChL55T09m/KXWAugEFiszwCaND6YhmCSCeWcM=";
          };
        };

        signal = {
          enable = true;
          enableNginx = true;
          domain = "netbird.${domain}";
        };
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
      netbird = prev.netbird.overrideAttrs (old: {
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
      dnsResolver = "192.168.100.4";
    };
    certs."netbird.ujaan.me" = {
      dnsProvider = "cloudflare";
      # environmentFile = "/run/secrets/cloudflare.env";
    };
  };

  systemd.services = {
    coturn.serviceConfig = {
      LoadCredential = [ "COTURN" ];
      Environment = [ ''COTURN_PASSWORD=%d/COTURN'' ];
      ExecStartPre = ''${pkgs.bash}/bin/bash -c 'cat "$CREDENTIALS_DIRECTORY/COTURN"' '';
    };

    netbird-management.serviceConfig = {
      Environment = ''
        NETBIRD_DOMAIN="netbird.ujaan.me"
        NETBIRD_DISABLE_LETSENCRYPT=true # behind reverse proxy
        NETBIRD_MGMT_API_PORT=443
        NETBIRD_SIGNAL_PORT=443
        TURN_MIN_PORT=40000
        TURN_MAX_PORT=40050
      '';
    };

    "acme-order-renew-netbird.ujaan.me".serviceConfig = {
      LoadCredential = [ "CLOUDFLARE" ];
      Environment = [ ''CLOUDFLARE_DNS_API_TOKEN_FILE=%d/CLOUDFLARE'' ];
      ExecStartPre = ''${pkgs.bash}/bin/bash -c 'cat "$CREDENTIALS_DIRECTORY/CLOUDFLARE"' '';
    };

    netbird-signal.serviceConfig = {
      Environment = [ "NB_PPROF_ADDR=6061" ];
    };
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=1G" ];
  };

  networking = {
    hostName = "vpn";
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowedUDPPorts = [
        3478
      ];
    };
    nameservers = [ "192.168.100.4" ];
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        Address = [ "192.168.100.5/24" ];
        Gateway = "192.168.100.1";
        DNS = [
          "192.168.100.1"
          "1.1.1.1"
        ];
        DHCP = "no";
      };
    };
  };

  users.users.default = {
    initialPassword = "password";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  nix = {
    enable = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = "nix-command flakes";
      warn-dirty = false;
    };
    channel.enable = false;
  };

  system.stateVersion = "24.11";
}
