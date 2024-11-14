{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.mukigg;
in {
  options.services.mukigg = {
    enable = mkEnableOption "mukigg service";

    addr = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Addr to bind to";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };

    user = mkOption {
      type = types.str;
      default = "mukigg";
      description = "User account under which mukigg runs";
    };

    group = mkOption {
      type = types.str;
      default = "mukigg";
      description = "Group under which mukigg runs";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/mukigg";
      description = "Directory to store mukigg data";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    systemd.services.mukigg = {
      description = "mukigg service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        PORT = toString cfg.port;
        ADDR = cfg.addr;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.mukigg}/bin/mukigg";
        Restart = "always";
        WorkingDirectory = cfg.dataDir;

        # Hardening options
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir ];
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        UMask = "0027";
      };
    };
  };
}
