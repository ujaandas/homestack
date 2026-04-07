{
  config,
  lib,
  ...
}:
let
  cfg = config.homestack.services.wireguard;
  relayForwardPorts = builtins.map (
    port: {
      proto = "tcp";
      sourcePort = port;
      destination = "${cfg.relay.peerAddress}:${toString port}";
    }
  ) cfg.relay.tcpPorts;
in
{
  options.homestack.services.wireguard = {
    enable = lib.mkEnableOption "Enable a WireGuard interface.";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "10.77.0.1/24";
      description = "WireGuard address for this node, including CIDR.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "UDP listen port for the WireGuard interface.";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the WireGuard private key file.";
    };

    peer = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Public key for the remote WireGuard peer.";
      };

      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "10.77.0.2/32" ];
        description = "Allowed IPs routed through the peer.";
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional peer endpoint as host:port.";
      };

      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        default = 25;
        description = "Persistent keepalive interval in seconds.";
      };
    };

    relay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable simple TCP relay forwarding to the WireGuard peer.";
      };

      peerAddress = lib.mkOption {
        type = lib.types.str;
        default = "10.77.0.2";
        description = "WireGuard peer IP that receives relayed traffic.";
      };

      tcpPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ ];
        description = "TCP ports to relay from this VM to relay.peerAddress over WireGuard.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.relay.enable) || cfg.relay.tcpPorts != [ ];
        message = "Set homestack.services.wireguard.relay.tcpPorts when relay mode is enabled.";
      }
    ];

    networking = {
      useNetworkd = true;

      firewall.allowedUDPPorts = [ cfg.listenPort ];
      firewall.allowedTCPPorts = lib.mkIf cfg.relay.enable cfg.relay.tcpPorts;

      wireguard.interfaces.${cfg.interfaceName} = {
        ips = [ cfg.address ];
        listenPort = cfg.listenPort;
        privateKeyFile = cfg.privateKeyFile;
        peers = [
          {
            publicKey = cfg.peer.publicKey;
            allowedIPs = cfg.peer.allowedIPs;
            endpoint = cfg.peer.endpoint;
            persistentKeepalive = cfg.peer.persistentKeepalive;
          }
        ];
      };

      nat = lib.mkIf cfg.relay.enable {
        enable = true;
        externalInterface = "eth0";
        forwardPorts = relayForwardPorts;
      };
    };
  };
}