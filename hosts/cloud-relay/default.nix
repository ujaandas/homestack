let
  domain = "ujaan.me";
  contactEmail = "ujaandas03@gmail.com";
  subnet = "192.168.100";
  vmIp = hostId: "${subnet}.${toString hostId}";
  relayProxyHostId = 10;
  relayTunnelHostId = 20;
in
{
  imports = [
    ../../secrets
    ../../modules/host/base.nix
    ../../modules/host/networking.nix
    ../../modules/host/hypervisor.nix
  ];

  homestack.host = {
    base = {
      enable = true;
      hostname = "cloud-relay";
      nixLdEnabled = true;
    };

    networking = {
      enable = true;
      externalInterface = "eth0";
      bridgeIp = "192.168.100.1";
    };

    hypervisor = {
      enable = true;

      ssh.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@cloud-relay"
      ];
      vms = [
        {
          name = "relay-proxy";
          enable = true;
          networking = {
            hostId = relayProxyHostId;
            TCPPorts = [
              22
              80
              443
            ];
          };
          services.caddy = {
            enable = true;
            inherit domain contactEmail;
            upstreams = {
              pocketid = "${vmIp relayTunnelHostId}:3000";
              netbird = "${vmIp relayTunnelHostId}:443";
            };
          };
        }

        {
          name = "relay-tunnel";
          enable = true;
          networking = {
            hostId = relayTunnelHostId;
            TCPPorts = [
              22
              443
              3000
            ];
            UDPPorts = [ 51820 ];
          };
          services.wireguard = {
            enable = true;
            interfaceName = "wg0";
            address = "10.77.0.1/24";
            listenPort = 51820;
            privateKeyFile = "/var/lib/wireguard/relay.key";
            peer = {
              publicKey = "REPLACE_WITH_LOCAL_HOST_WIREGUARD_PUBLIC_KEY";
              allowedIPs = [ "10.77.0.2/32" ];
              persistentKeepalive = 25;
            };

            relay = {
              enable = true;
              peerAddress = "10.77.0.2";
              tcpPorts = [
                3000
                443
              ];
            };
          };
        }
      ];
    };
  };

  system.stateVersion = "25.05";
}
