{ config, lib, ... }:
let
  cfg = config.homestack.host.hypervisor;
  hypervisorAddressing = import ../../../lib/hypervisor-addressing.nix { inherit lib; };
  vmsByName = builtins.listToAttrs (
    builtins.map (vm: {
      inherit (vm) name;
      value = vm;
    }) cfg.vms
  );

  enabledResolvedVms = hypervisorAddressing.mkResolvedEnabledVms cfg;

  allServices = [
    ../../services/postgres.nix
    ../../services/pocket-id.nix
    ../../services/caddy.nix
    ../../services/dnsmasq.nix
    ../../services/netbird.nix
  ];
in
{
  config = lib.mkIf cfg.enable {
    microvm.vms = lib.mapAttrs (
      name: vm:
      let
        networkingValues = enabledResolvedVms.${name}.networking;
        mergedCredentialFiles = lib.foldl' lib.recursiveUpdate { } vm.credentialFiles;
      in
      lib.mkIf vm.enable {
        autostart = true;
        restartIfChanged = true;

        config = {
          _module.args.vmContext = lib.recursiveUpdate (lib.recursiveUpdate cfg.context vm.context) {
            currentVm = name;
            inherit (config.homestack.host.networking) bridgeIp;
            vms = lib.mapAttrs (_: resolvedVm: resolvedVm.networking) enabledResolvedVms;
          };

          imports = allServices;
          microvm = {
            inherit (vm.hardware) mem vcpu;
            credentialFiles = mergedCredentialFiles;

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

          services = {
            openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = cfg.ssh.allowPasswordAuthentication;
                KbdInteractiveAuthentication = cfg.ssh.allowPasswordAuthentication;
                PermitRootLogin = "no";
              };
            };
          };

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
