{
  modulesPath,
  config,
  system,
  lib,
  pkgs,
  ...
}:
let
  domain = "ujaan.me";
  contactEmail = "ujaandas03@gmail.com";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
    ../../secrets
    ../../modules/host/base.nix
    ../../modules/services/caddy.nix
    ../../modules/services/wireguard.nix
  ];

  boot.loader.grub = {
    enable = true;
  };

  # This host is provisioned on Hetzner where firmware mode can vary.
  # Force GRUB and avoid inheriting systemd-boot from shared host defaults.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  nix.settings = {
    trusted-public-keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@sachiel"
    ];
  };

  users.users.default = {
    isNormalUser = true;
    initialPassword = "password";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0qzwBbh1pvVIbliC0PnBVJkcdLYJhFEljw95Zre1i0 default@sachiel"
    ];
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  homestack = {
    host = {
      base = {
        enable = true;
        hostname = "cloud-relay";
      };
      secrets.enabledNames = [
        "cloudflare_dns_key"
        "wireguard_ingress_key"
      ];
    };

    services = {
      caddy = {
        enable = true;
        inherit domain contactEmail;
        upstreams = {
          pocketid = "10.77.0.2:3000";
          netbird = "10.77.0.2";
        };
      };

      wireguard = {
        enable = true;
        interfaceName = "wg0";
        address = "10.77.0.1/24";
        listenPort = 51820;
        privateKeyFile = config.age.secrets.wireguard_ingress_key.path;
        peer = {
          publicKey = "HOVgj99NRFC6bYNmR+bxJuRleX1VOvvWgDlCJQLmRQs=";
          allowedIPs = [ "10.77.0.2/32" ];
          persistentKeepalive = 25;
        };

        relay = {
          enable = true;
          externalInterface = "eth0";
          peerAddress = "10.77.0.2";
          # Keep host HTTPS free for Caddy; relay only app traffic over WireGuard.
          tcpPorts = [ 3000 ];
        };
      };
    };
  };

  systemd.services.caddy.serviceConfig.LoadCredential = lib.mkForce [
    "CLOUDFLARE_DNS_KEY:${config.age.secrets.cloudflare_dns_key.path}"
  ];

  system.stateVersion = "25.05";
}
