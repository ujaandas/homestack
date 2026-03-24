{ config, lib, ... }:
let
  cfg = config.homestack.host.networking;
in
{
  options.homestack.host.networking = {
    enable = lib.mkEnableOption "Use sane networking defaults for host.";

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
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useNetworkd = true;

      nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
      };

      interfaces.eth0.useDHCP = true;

      firewall = {
        enable = true;
      };
    };
  };
}
