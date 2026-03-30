{
  lib,
  config,
  ...
}:
let
  cfg = config.homestack.services.netbird;
in
{
  imports = [
    ./base.nix
    ./coturn.nix
    ./dashboard.nix
    ./management.nix
    ./signal.nix
  ];

  options.homestack.services.netbird = {
    enable = lib.mkEnableOption "Enable NetBird self-hosted VPN stack.";

    roles = {
      coturn = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable NetBird TURN role.";
      };

      dashboard = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable NetBird dashboard role.";
      };

      management = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable NetBird management role.";
      };

      signal = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable NetBird signal role.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.roles.coturn
          || cfg.roles.dashboard
          || cfg.roles.management
          || cfg.roles.signal;
        message = "At least one NetBird role must be enabled when homestack.services.netbird.enable = true.";
      }
    ];
  };
}
