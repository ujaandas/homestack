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
  ];

  # Base settings
  homestack.base = {
    enable = true;
    hostname = "sachiel";
  };

  system.stateVersion = "25.05";
}
