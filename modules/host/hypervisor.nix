{ config, lib, ... }:
let
  cfg = config.homestack.host.hypervisor;
in
{
  options.homestack.host.hypervisor = {
    enable = lib.mkEnableOption "Enable and configure hypervisor capabilities for host.";

    vms = lib.mkOption {
      type = lib.types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "Enable VM ${name}";

              module = lib.mkOption {
                type = lib.types.path;
                description = "Path to VM module";
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
                storage = lib.mkOption {
                  type = lib.types.int;
                  default = 512;
                };

                memory = lib.mkOption {
                  type = lib.types.int;
                  default = 1024;
                };

                vcpu = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                };

                credentialFiles = lib.mkOption {
                  default = { };
                  type = lib.types.attrsOf lib.types.path;
                };
              };
              extraConfig = mkOption {
                type = types.attrs;
                default = { };
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
    microvms.vms = lib.mapAttrs (
      name: vm:
      lib.mkIf vm.enable {
        autostart = true;
        restartIfChanged = true;

        config = {
          imports = [ vm.module ];
          microvm = {
            mem = vm.hardware.memory;
            vcpu = vm.hardware.vcpu;

            volumes = [
              {
                mountPoint = "/";
                image = "root.img";
                size = vm.hardware.storage;
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
                mac = vm.networking.mac;
              }
            ];
          }
          // vm.extraConfig;

          networking = {
            hostname = name;
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

          services.openssh.enable = true;
        };
      }
    ) cfg.vms;
  };
}
