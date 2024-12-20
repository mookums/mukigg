{
  description = "The muki.gg website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    iguana.url = "github:mookums/iguana";
  };

  outputs = {
    nixpkgs,
    iguana,
    ...
  }: let
    iguanaLib = iguana.lib.${system};

    mukiggPackage = iguanaLib.mkZigPackage {
      pname = "mukigg";
      version = "0.1.0";
      src = ./.;
      doCheck = false;
    };

    mukiggModule = {
      config,
      lib,
      pkgs,
      ...
    }:
      with lib; let
        cfg = config.services.mukigg;
      in {
        options.services.mukigg = {
          enable = mkEnableOption "mukigg service";

          port = mkOption {
            type = types.port;
            default = 9862;
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

          users.groups.${cfg.group} = {};

          systemd.services.mukigg = {
            description = "mukigg service";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];

            environment = {PORT = toString cfg.port;};

            serviceConfig = {
              Type = "simple";
              User = cfg.user;
              Group = cfg.group;
              ExecStart = "${mukiggPackage}/bin/mukigg";
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
              ReadWritePaths = [cfg.dataDir];
              RemoveIPC = true;
              RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = ["@system-service"];
              UMask = "0027";
            };
          };
        };
      };

    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages = {
      default = mukiggPackage;
      mukigg = mukiggPackage;
    };

    nixosModules = {
      default = mukiggModule;
      mukigg = mukiggModule;
    };

    devShells.${system}.default = iguanaLib.mkShell {
      withZls = true;

      extraPackages = with pkgs; [
        # Watch
        entr
        # Benchmarking
        wrk
      ];
    };
  };
}
