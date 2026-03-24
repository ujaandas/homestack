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
    ../../modules/host/base.nix
    ../../modules/host/networking.nix
    ../../modules/host/hypervisor.nix
  ];

  # Base settings
  homestack.host = {
    base = {
      enable = true;
      hostname = "sachiel";
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
          services.postgres = {
            enable = true;
            databases = [ "pocketid" ];
            users = [
              {
                name = "pocketid";
                ensureDBOwnership = true;
              }
            ];
            authentication = "host pocketid pocketid 192.168.100.0/24 trust";
          };
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
