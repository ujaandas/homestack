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

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain used for NetBird endpoints.";
    };

    proxyIp = lib.mkOption {
      type = lib.types.str;
      description = "DNS resolver IP used by ACME/networking defaults.";
    };

    contactEmail = lib.mkOption {
      type = lib.types.str;
      default = "ujaandas03@gmail.com";
      description = "Contact email used by ACME.";
    };

    clientId = lib.mkOption {
      type = lib.types.str;
      default = "4716b464-7a15-4e06-aadd-b985650f2cba";
      description = "OIDC client ID/audience used by NetBird dashboard and management.";
    };

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
        assertion = cfg.roles.coturn || cfg.roles.dashboard || cfg.roles.management || cfg.roles.signal;
        message = "At least one NetBird role must be enabled when homestack.services.netbird.enable = true.";
      }
    ];
  };
}
