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

  secrets.pocketid_enc_key.enable = true;

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
            ip = "192.168.100.2";
            mac = "02:00:00:00:00:01";
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
            ip = "192.168.100.3";
            mac = "02:00:00:00:00:02";
            TCPPorts = [
              22
              3000
            ];
          };
          services.pocket-id.enable = true;
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
