{ lib, ... }:
{
  options.homestack.host.hypervisor = {
    enable = lib.mkEnableOption "Enable and configure hypervisor capabilities for host.";

    context = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Arbitrary values passed to all guest VMs as vmContext.";
    };

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

              context = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Additional vmContext values for this VM (merged over hypervisor-level context).";
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
}
