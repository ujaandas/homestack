{ config, lib, ... }:
let
  cfg = config.homestack.host.hypervisor;
  hypervisorAddressing = import ../../lib/hypervisor-addressing.nix { inherit lib; };
  vmsByName = builtins.listToAttrs (
    builtins.map (vm: {
      inherit (vm) name;
      value = vm;
    }) cfg.vms
  );

  enabledResolvedVms = hypervisorAddressing.mkResolvedEnabledVms cfg;
  maxAutoHostId = hypervisorAddressing.mkMaxAutoHostId cfg;
  vmHostEntries = hypervisorAddressing.mkHostEntries enabledResolvedVms;
  vmSshAliases = hypervisorAddressing.mkSshAliases {
    inherit enabledResolvedVms;
    inherit (cfg.ssh) user;
  };

  allServices = [
    ../services/postgres.nix
    ../services/pocket-id.nix
    ../services/caddy.nix
    ../services/dnsmasq.nix
  ];
in
{
  options.homestack.host.hypervisor = {
    enable = lib.mkEnableOption "Enable and configure hypervisor capabilities for host.";

    ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Generate SSH client aliases and local hostnames for enabled microVMs.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "default";
        description = "Default SSH username for auto-generated VM host aliases.";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys authorized for the default guest VM user.";
      };

      allowPasswordAuthentication = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow password-based SSH authentication for guest VMs.";
      };
    };

    addressing = {
      ipSubnet = lib.mkOption {
        type = lib.types.str;
        default = "192.168.100";
        description = "IPv4 subnet prefix used for auto-generated VM addresses (without final host octet).";
      };

      ipHostStart = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Starting host octet for auto-generated VM IPv4 addresses.";
      };

      macPrefix = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00";
        description = "MAC prefix used for auto-generated VM MAC addresses; final byte is auto-derived per VM.";
      };
    };

    vms = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (
          {
            name,
            ...
          }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Name for this VM.";
              };

              enable = lib.mkEnableOption "Enable VM";

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
                hostId = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Host octet (1-254) used for auto-generated IP/MAC for this VM; null uses sequential allocation.";
                };

                ip = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Static IPv4 address for VM; if null, one is auto-generated.";
                };

                mac = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "MAC address for VM; if null, one is auto-generated.";
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
      {
        assertion = cfg.addressing.ipHostStart >= 1;
        message = "homestack.host.hypervisor.addressing.ipHostStart must be >= 1";
      }
      {
        assertion = maxAutoHostId <= 254;
        message = "Auto-generated VM IP host octets exceed 254; lower ipHostStart or reduce VM count.";
      }
      {
        assertion = lib.length (lib.unique (builtins.map (vm: vm.name) cfg.vms)) == lib.length cfg.vms;
        message = "homestack.host.hypervisor.vms must not contain duplicate VM names.";
      }
      {
        assertion = lib.all (
          vm: vm.networking.hostId == null || (vm.networking.hostId >= 1 && vm.networking.hostId <= 254)
        ) cfg.vms;
        message = "Each VM networking.hostId must be null or between 1 and 254.";
      }
    ];

    networking.bridges.br0.interfaces = builtins.attrNames vmsByName;
    networking.hosts = lib.mkIf cfg.ssh.enable vmHostEntries;

    programs.ssh = lib.mkIf cfg.ssh.enable {
      extraConfig = vmSshAliases;
    };

    microvm.vms = lib.mapAttrs (
      name: vm:
      let
        networkingValues = enabledResolvedVms.${name}.networking;
      in
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
                inherit (networkingValues) mac;
              }
            ];
          };

          homestack.services = vm.services;

          services = lib.mkMerge [
            {
              openssh = {
                enable = true;
                settings = {
                  PasswordAuthentication = cfg.ssh.allowPasswordAuthentication;
                  KbdInteractiveAuthentication = cfg.ssh.allowPasswordAuthentication;
                  PermitRootLogin = "no";
                };
              };
            }
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
                Address = [ "${networkingValues.ip}/24" ];
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
            isNormalUser = true;
            initialHashedPassword = "!";
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = cfg.ssh.authorizedKeys;
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
    ) vmsByName;
  };
}
