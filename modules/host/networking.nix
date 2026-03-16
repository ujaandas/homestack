{ config, lib, ... }:
let
  cfg = config.homestack.networking;
in
{
  options.homestack.networking = {
    enable = lib.mkEnableOption "MicroVM bridging and NAT routing.";
    externalInterface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "External network interface for this host.";
    };
    bridgeIp = lib.mkOption {
      type = lib.types.str;
      default = "192.168.100.1";
      description = "Host bridge IP address.";
    };
    guestInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of interface names to look for.";
    };
    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IP address of guest nameservers.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      inherit (cfg.nameservers) ;
      useNetworkd = true;

      bridges.br0.interfaces = cfg.guestInterfaces;
      nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
        inherit (cfg.externalInterface) ;
      };

      firewall = {
        enable = true;
      };
    };
  };
}
