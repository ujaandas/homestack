{
  config,
  system,
  lib,
  pkgs,
  agenix,
  ...
}:
# These are "global" settings that apply to every NixOS machine/host on Homestack.
let
  cfg = config.homestack.base;
in
{
  options.homestack.base = {
    enable = lib.mkEnableOption "Enable sane defaults for this host.";

    username = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Set username for this host.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "homelab";
      description = "Set networking hostname for this host.";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/London";
      description = "Set timezone for this host, in format <Continent>/<Country>, like Europe/London.";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_GB";
      description = "Set locale code, in format <LANGUAGE>_<COUNTRY>, like en_GB.";
    };

    sshEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSH on this host.";
    };

    nixLdEnabled = lib.mkEnableOption "Enable nix-ld for this host (useful if you plan to SSH with VSCode or other forks)";

    systemPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional system-wide packages to install on this host.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Nix daemon settings
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

    # Bootloader crap
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Locales and time stuff
    time.timeZone = cfg.timezone;

    i18n = {
      defaultLocale = "${cfg.locale}.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "${cfg.locale}.UTF-8";
        LC_IDENTIFICATION = "${cfg.locale}.UTF-8";
        LC_MEASUREMENT = "${cfg.locale}.UTF-8";
        LC_MONETARY = "${cfg.locale}.UTF-8";
        LC_NAME = "${cfg.locale}.UTF-8";
        LC_NUMERIC = "${cfg.locale}.UTF-8";
        LC_PAPER = "${cfg.locale}.UTF-8";
        LC_TELEPHONE = "${cfg.locale}.UTF-8";
        LC_TIME = "${cfg.locale}.UTF-8";
      };
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # System packages and programs
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages =
      with pkgs;
      [
        vim
        tmux
        git
        coreutils
      ]
      ++ [ agenix.packages.${system}.default ]
      ++ cfg.systemPackages;

    programs.direnv.enable = true;
    programs.nix-ld.enable = cfg.nixLdEnabled;

    services.openssh.enable = cfg.sshEnabled;

    # User settings
    users.users.${cfg.username} = {
      isNormalUser = true;
      description = cfg.username;
      initialPassword = "password";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };

    networking.hostName = cfg.hostname;
  };
}
