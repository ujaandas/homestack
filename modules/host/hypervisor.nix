{ config, lib, ... }:
let
  cfg = config.homestack.host.hypervisor;
  allServices = [
    ../services/postgres.nix
    ../services/pocket-id.nix
  ];
in
{
  options.homestack.host.hypervisor = {
    enable = lib.mkEnableOption "Enable and configure hypervisor capabilities for host.";

    vms = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "Enable VM ${name}";

              services = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };

              credentialFiles = lib.mkOption {
                type = lib.types.listOf (lib.types.attrsOf lib.types.path);
                default = [ ];
                description = "List of credential file sets to inject into this VM via microvm.credentialFiles.";
              };

              networking = {
                ip = lib.mkOption {
                  type = lib.types.str;
                  description = "Static IP for VM";
                };

                mac = lib.mkOption {
                  type = lib.types.str;
                  default = "02:00:00:00:00:00";
                };

                UDPPorts = lib.mkOption {
                  type = lib.types.listOf lib.types.port;
                  default = [ ];
                };

                TCPPorts = lib.mkOption {
                  type = lib.types.listOf lib.types.port;
                  default = [ ];
                };
              };

              hardware = {
                size = lib.mkOption {
                  type = lib.types.int;
                  default = 512;
                };

                mem = lib.mkOption {
                  type = lib.types.int;
                  default = 1024;
                };

                vcpu = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                };
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config ? microvm;
        message = "microvm module must be imported when using homestack.host.hypervisor";
      }
    ];

    networking.bridges.br0.interfaces = builtins.attrNames cfg.vms;

    microvm.vms = lib.mapAttrs (
      name: vm:
      lib.mkIf vm.enable {
        autostart = true;
        restartIfChanged = true;

        config = {
          imports = allServices;
          microvm = {
            inherit (vm.hardware) mem vcpu;
            credentialFiles = lib.mkMerge vm.credentialFiles;

            volumes = [
              {
                mountPoint = "/";
                image = "root.img";
                inherit (vm.hardware) size;
              }
            ];

            shares = [
              {
                proto = "virtiofs";
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              }
            ];

            interfaces = [
              {
                type = "tap";
                id = name;
                inherit (vm.networking) mac;
              }
            ];
          };

          homestack.services = vm.services;

          services = lib.mkMerge [
            { openssh.enable = true; }
          ];

          networking = {
            hostName = name;
            useNetworkd = true;
            firewall.allowedTCPPorts = vm.networking.TCPPorts;
            firewall.allowedUDPPorts = vm.networking.UDPPorts;
          };

          systemd.network = {
            enable = true;
            networks."20-lan" = {
              matchConfig.Type = "ether";
              networkConfig = {
                Address = [ "${vm.networking.ip}/24" ];
                Gateway = config.homestack.host.networking.bridgeIp;
                DNS = [
                  config.homestack.host.networking.bridgeIp
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

          system.stateVersion = "26.05";
        };
      }
    ) cfg.vms;
  };
}
