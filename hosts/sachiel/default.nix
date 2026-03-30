{
  config,
  system,
  lib,
  pkgs,
  agenix,
  ...
}:

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

    # Hypervisor network settings
    networking = {
      enable = true;
      externalInterface = "eth0";
      bridgeIp = "192.168.100.1";
    };

    # Hypervisor VM settings
    hypervisor = {
      enable = true;
      context = {
        domain = "ujaan.me";
        contact.email = "ujaandas03@gmail.com";
      };
      ssh.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@sachiel"
      ];
      vms = [
        {
          name = "db";
          enable = true;
          networking = {
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
            TCPPorts = [
              22
              3000
            ];
          };
          services.pocket-id.enable = true;
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
            TCPPorts = [
              22
              53
              80
              443
            ];
            UDPPorts = [ 53 ];
          };
          services = {
            caddy.enable = true;
            dnsmasq.enable = true;
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
            TCPPorts = [
              22
              80
              443
            ];
            UDPPorts = [ 3478 ];
          };
          hardware.size = 1024;
          services.netbird.enable = true;
        }
      ];
    };
  };

  system.stateVersion = "25.05";
}
