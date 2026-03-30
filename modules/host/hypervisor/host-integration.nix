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
  maxAutoHostId = hypervisorAddressing.mkMaxAutoHostId cfg;
  vmHostEntries = hypervisorAddressing.mkHostEntries enabledResolvedVms;
  vmSshAliases = hypervisorAddressing.mkSshAliases {
    inherit enabledResolvedVms;
    inherit (cfg.ssh) user;
  };
in
{
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
  };
}
