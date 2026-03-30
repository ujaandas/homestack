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
      vms = {

        db = {
          enable = true;
          networking = {
            hostId = 2;
            TCPPorts = [
              22
              5432
            ];
          };
          services.postgres.enable = true;
        };

        auth = {
          enable = true;
          credentialFiles = [
            {
              POCKETID_ENC_KEY = config.age.secrets.pocketid_enc_key.path;
            }
          ];
          networking = {
            hostId = 3;
            TCPPorts = [
              22
              3000
            ];
          };
          services.pocket-id.enable = true;
        };

        proxy = {
          enable = true;
          credentialFiles = [
            {
              CLOUDFLARE_DNS_KEY = config.age.secrets.cloudflare_dns_key.path;
            }
          ];
          networking = {
            hostId = 4;
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
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
