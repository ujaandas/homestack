{ lib, pkgs, ... }:
{
  imports = [
    ./microvm-configuration.nix
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = [ "pocketid" ];
    ensureUsers = [
      {
        name = "pocketid";
        ensureDBOwnership = true;
      }
    ];
    settings = {
      listen_addresses = lib.mkForce "*";
      # ssl = true;
    };

    authentication = lib.mkOverride 10 ''
      local all all trust
      host pocketid pocketid 192.168.100.0/24 trust
      hostssl pocketid pocketid 192.168.100.0/24 trust
    '';
  };

  networking = {
    hostName = "db";
    useNetworkd = true;
    firewall.allowedTCPPorts = [
      22
      5432
    ];
  };

  systemd.network.enable = true;

  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    networkConfig = {
      Address = [ "192.168.100.2/24" ];
      Gateway = "192.168.100.1";
      DNS = [
        "192.168.100.1"
        "1.1.1.1"
      ];
      DHCP = "no";
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

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
