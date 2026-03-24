{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.postgres;
in
{
  options.services.postgres = {
    enable = lib.mkEnableOption "Enable sane PostgreSQL service.";

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
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

      settings.listen_addresses = lib.mkForce "*";

      authentication = lib.mkOverride 10 ''
        local all all trust
        host pocketid pocketid 192.168.100.0/24 trust
      '';
    };

    networking.firewall.allowedTCPPorts = [ 5432 ];
  };
}
