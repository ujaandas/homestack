{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homestack.vm.services.postgres;
in
{
  options.homestack.vm.services.postgres = {
    enable = lib.mkEnableOption "Enable PostgreSQL";

    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };

    authentication = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;

      ensureDatabases = cfg.databases;
      ensureUsers = cfg.users;

      settings.listen_addresses = lib.mkForce "*";

      authentication = lib.mkOverride 10 ''
        local all all trust
        ${cfg.authentication}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 5432 ];

  };
}
