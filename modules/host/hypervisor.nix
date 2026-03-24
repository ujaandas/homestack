{ config, lib, ... }:
let
  servicesDir = ../services;
  services = builtins.attrNames (builtins.readDir servicesDir);
  cfg = config.homestack.host.hypervisor;
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
                type = lib.types.attrsOf (
                  lib.types.submodule (
                    { name2, ... }:
                    {
                      options = {
                        enable = lib.mkEnableOption "Enable VM service ${name2}.";
                        extraConfig = lib.mkOption {
                          type = lib.types.attrs;
                          default = { };
                        };
                      };
                    }
                  )
                );
                default = { };
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

                credentialFiles = lib.mkOption {
                  default = { };
                  type = lib.types.attrsOf lib.types.path;
                };
              };

              extraConfig = lib.mkOption {
                type = lib.types.attrs;
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

    networking.bridges.br0.interfaces = builtins.attrNames cfg.vms;

    microvm.vms = lib.mapAttrs (
      name: vm:
      lib.mkIf vm.enable {
        autostart = true;
        restartIfChanged = true;

        config = {
          imports = builtins.map (s: import "${servicesDir}/${s}.nix") (
            builtins.filter (name: vm.services ? name && vm.services.${name}.enable) services
          );

          microvm = {
            inherit (vm.hardware) mem;
            inherit (vm.hardware) vcpu;

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
          }
          // vm.extraConfig;

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

          services.openssh.enable = true;
        };
      }
    ) cfg.vms;
  };
}
