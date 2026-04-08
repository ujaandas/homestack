{
  config,
  system,
  lib,
  pkgs,
  agenix,
  ...
}:
let
  domain = "ujaan.me";
  contactEmail = "ujaandas03@gmail.com";
  cloudRelayEndpoint = "204.168.141.116:51820";
  subnet = "192.168.100";
  vmIp = hostId: "${subnet}.${toString hostId}";

  vmHostIds = {
    db = 2;
    auth = 3;
    proxy = 4;
    vpn = 5;
    egress = 6;
  };
in

# Sachiel, the hypervisor
{
  imports = [
    ./hardware-configuration.nix
    ../../secrets
    ../../modules/host/base.nix
    ../../modules/host/networking.nix
    ../../modules/host/hypervisor.nix
  ];

  # Base settings
  homestack.host = {
    base = {
      enable = true;
      hostname = "sachiel";
      nixLdEnabled = true;
    };

    secrets.enabledNames = [
      "cloudflare_dns_key"
      "netbird_data_store_enc_key"
      "netbird_pocketid_api_key"
      "netbird_relay_key"
      "netbird_turn_key"
      "pocketid_enc_key"
      "wireguard_egress_key"
    ];

    # Hypervisor network settings
    networking = {
      enable = true;
      externalInterface = "eth0";
      bridgeIp = "192.168.100.1";
    };

    # Hypervisor VM settings
    hypervisor = {
      enable = true;
      ssh.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@sachiel"
      ];
      vms = [
        {
          name = "db";
          enable = true;
          networking = {
            hostId = vmHostIds.db;
            TCPPorts = [
              22
              5432
            ];
          };
          services.postgres.enable = true;
        }

        {
          name = "auth";
          enable = true;
          credentialFiles = [
            {
              POCKETID_ENC_KEY = config.age.secrets.pocketid_enc_key.path;
            }
          ];
          networking = {
            hostId = vmHostIds.auth;
            TCPPorts = [
              22
              3000
            ];
          };
          services.pocket-id = {
            enable = true;
            inherit domain;
            authIp = vmIp vmHostIds.auth;
            dbIp = vmIp vmHostIds.db;
          };
        }

        {
          name = "proxy";
          enable = true;
          credentialFiles = [
            {
              CLOUDFLARE_DNS_KEY = config.age.secrets.cloudflare_dns_key.path;
            }
          ];
          networking = {
            hostId = vmHostIds.proxy;
            TCPPorts = [
              22
              53
              80
              443
            ];
            UDPPorts = [ 53 ];
          };
          services = {
            caddy = {
              enable = true;
              inherit domain contactEmail;
              upstreams = {
                pocketid = "${vmIp vmHostIds.auth}:3000";
                netbird = "${vmIp vmHostIds.vpn}";
              };
            };

            dnsmasq = {
              enable = true;
              inherit domain;
              proxyIp = vmIp vmHostIds.proxy;
            };
          };
        }

        {
          name = "vpn";
          enable = true;
          credentialFiles = [
            {
              CLOUDFLARE_DNS_KEY = config.age.secrets.cloudflare_dns_key.path;
              DATA_STORE_ENC_KEY = config.age.secrets.netbird_data_store_enc_key.path;
              POCKETID_API_KEY = config.age.secrets.netbird_pocketid_api_key.path;
              RELAY_KEY = config.age.secrets.netbird_relay_key.path;
              TURN_KEY = config.age.secrets.netbird_turn_key.path;
            }
          ];
          networking = {
            hostId = vmHostIds.vpn;
            TCPPorts = [
              22
              80
              443
            ];
            UDPPorts = [ 3478 ];
          };
          hardware.size = 1024;
          services.netbird = {
            enable = true;
            inherit domain contactEmail;
            proxyIp = vmIp vmHostIds.proxy;
          };
        }

        {
          name = "egress";
          enable = true;
          credentialFiles = [
            {
              WG_EGRESS_PRIV_KEY = config.age.secrets.wireguard_egress_key.path;
            }
          ];
          networking = {
            hostId = vmHostIds.egress;
            TCPPorts = [ 22 ];
          };
          services.wireguard = {
            enable = true;
            interfaceName = "wg0";
            address = "10.77.0.2/24";
            privateKeyFile = "WG_EGRESS_PRIV_KEY";
            peer = {
              publicKey = "hekhMcqcBeJbwScN51soaO1/BjVIhA2eBDPN5/Pt5Wg=";
              endpoint = cloudRelayEndpoint;
              allowedIPs = [
                "10.77.0.1/32"
              ];
              persistentKeepalive = 25;
            };

            relay = {
              enable = true;
              externalInterface = "eth0";
            };
          };
        }
      ];
    };
  };

  system.stateVersion = "25.05";
}
