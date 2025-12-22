{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    genAttrs
    ;

  vmDir = ./. + "../../../vms";

  vms = builtins.attrNames (lib.filterAttrs (_: v: v == "directory") (builtins.readDir vmDir));
in
{
  options.vms = genAttrs vms (name: {
    enable = mkEnableOption "Enable VM ${name}";
  });

  config.microvm.vms = genAttrs vms (
    name:
    mkIf config.vms.${name}.enable {
      config = import "${vmDir}/${name}";
      autostart = true;
      restartIfChanged = true;
    }
  );
}

# This is extremely janky.
