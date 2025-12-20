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
          settings = {
            AUTH_AUTHORITY = "https://pocketid.${domain}";
            USE_AUTH0 = false;
            AUTH_AUDIENCE = clientId;
            AUTH_CLIENT_ID = clientId;
            AUTH_SUPPORTED_SCOPES = "openid profile email groups";
            NETBIRD_TOKEN_SOURCE = "idToken";
            AUTH_REDIRECT_URI="/auth";
            AUTH_SILENT_REDIRECT_URI="/silent-auth";
            
          };
        };

        management = {
          enable = true;
          enableNginx = true;
          disableAnonymousMetrics = true;
          oidcConfigEndpoint = "https://pocketid.${domain}/.well-known/openid-configuration";

          settings = {
            Signal.URI = "netbird.${domain}:443";

            HttpConfig.AuthAudience = clientId;
            IdpManagerConfig.ClientConfig.ClientID = clientId;

            DeviceAuthorizationFlow.ProviderConfig = {
              Audience = clientId;
              ClientID = clientId;
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
        3478
        10000
        33080
      ];
      allowedUDPPorts = [
        3478
        5349
        33080
      ];
      allowedUDPPortRanges = [
        {
          from = 40000;
          to = 40050;
        }
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
