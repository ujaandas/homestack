{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "ujaan.me";
in
{
  imports = [
    ./microvm-configuration.nix
  ];

  services = {
    openssh.enable = true;

    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
        hash = "sha256-ea8PC/+SlPRdEVVF/I3c1CBprlVp1nrumKM5cMwJJ3U=";
      };
      email = "ujaandas03@gmail.com";
      globalConfig = ''
        admin off
      '';
      virtualHosts = {
        "*.${domain}".extraConfig = ''
          reverse_proxy 192.168.100.3:3000
          tls {
            dns cloudflare {file.{$CLOUDFLARE_API_KEY}}
          }
        '';
      };
    };

    dnsmasq = {
      enable = true;
      settings = {
        listen-address = "192.168.100.4";
        bind-interfaces = true;
        server = [ "1.1.1.1" ];
        address = [
          "/pocketid.${domain}/192.168.100.4"
        ];
      };
    };
  };

  systemd = {
    services.caddy = {
      serviceConfig = {
        LoadCredential = [ "CLOUDFLARE" ];
        Environment = [ ''CLOUDFLARE_API_KEY=%d/CLOUDFLARE'' ];
        ExecStartPre = ''${pkgs.bash}/bin/bash -c 'cat "$CREDENTIALS_DIRECTORY/CLOUDFLARE"' '';
      };
    };
  };

  networking = {
    hostName = "proxy";
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = [
        22
        80
        53
        443
      ];
      allowedUDPPorts = [ 53 ];
    };
  };

  systemd.network = {
    enable = true;
    networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        Address = [ "192.168.100.4/24" ];
        Gateway = "192.168.100.1";
        DNS = [
          "192.168.100.1"
          "1.1.1.1"
        ];
        DHCP = "no";
      };
    };
  };

  users.users.default = {
    initialPassword = "password";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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

  system.stateVersion = "24.11";
}
