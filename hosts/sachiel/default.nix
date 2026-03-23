{
  config,
  system,
  lib,
  pkgs,
  agenix,
  ...
}:

# Sachiel, the hypervisor
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host/base.nix
    ../../modules/host/networking.nix
  ];

  # Base settings
  homestack.base = {
    enable = true;
    hostname = "sachiel";
  };

  # Hypervisor network settings
  homestack.networking = {
    enable = true;
    externalInterface = "eth0";
    bridgeIp = "192.168.100.1";
    nameservers = [ "192.168.100.4" ];
  };

  # Hypervisor VM settings
  homestack.vms = {
    enable = true;

  };

  system.stateVersion = "25.05";
}
