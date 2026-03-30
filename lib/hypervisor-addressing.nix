{ lib }:
rec {
  math = import ./math.nix;

  mkVmNames = cfg: builtins.map (vm: vm.name) cfg.vms;

  mkEnabledVmsByName =
    cfg:
    builtins.listToAttrs (
      builtins.map (vm: {
        inherit (vm) name;
        value = vm;
      }) (lib.filter (vm: vm.enable) cfg.vms)
    );

  mkVmIndexMap =
    vmNames:
    builtins.listToAttrs (
      builtins.genList (idx: {
        name = builtins.elemAt vmNames idx;
        value = idx;
      }) (builtins.length vmNames)
    );

  toHexByte =
    n:
    let
      hexDigits = [
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
      ];
      hi = builtins.div n 16;
      lo = math.mod n 16;
    in
    "${builtins.elemAt hexDigits hi}${builtins.elemAt hexDigits lo}";

  resolveVmNetworking =
    {
      addressing,
      vmIndexMap,
      name,
      vm,
    }:
    let
      hostId =
        if vm.networking.hostId != null then
          vm.networking.hostId
        else
          addressing.ipHostStart + vmIndexMap.${name};
      generatedIp = "${addressing.ipSubnet}.${toString hostId}";
      generatedMac = "${addressing.macPrefix}:${toHexByte hostId}";
    in
    vm.networking
    // {
      ip = if vm.networking.ip == null then generatedIp else vm.networking.ip;
      mac = if vm.networking.mac == null then generatedMac else vm.networking.mac;
    };

  mkResolvedEnabledVms =
    cfg:
    let
      vmNames = mkVmNames cfg;
      vmIndexMap = mkVmIndexMap vmNames;
      enabledVms = mkEnabledVmsByName cfg;
    in
    lib.mapAttrs (
      name: vm:
      vm
      // {
        networking = resolveVmNetworking {
          inherit (cfg) addressing;
          inherit vmIndexMap name vm;
        };
      }
    ) enabledVms;

  mkHostEntries =
    enabledResolvedVms:
    lib.mapAttrs' (
      name: vm:
      lib.nameValuePair vm.networking.ip [
        name
        "${name}.vm"
      ]
    ) enabledResolvedVms;

  mkSshAliases =
    {
      enabledResolvedVms,
      user,
    }:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: vm: ''
        Host ${name} ${name}.vm
          HostName ${vm.networking.ip}
          User ${user}
      '') enabledResolvedVms
    );

  mkMaxAutoHostId =
    cfg:
    let
      enabledVms = lib.filter (vm: vm.enable) cfg.vms;
    in
    cfg.addressing.ipHostStart + (builtins.length enabledVms) - 1;
}
