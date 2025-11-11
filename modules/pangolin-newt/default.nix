{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "pangolin-newt";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  ip = config.nps.hostIP4Address;

  category = "Network & Administration";
  displayName = "Pangolin Newt";
  description = "A tunneling client for Pangolin";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "config.yml";
      description = ''
        Pangolin Newt configuration. Will be converted to the `config.yml`.
        For a full list of options, refer to the [Pangolin Newt documentation](https://docs.pangolin.net/manage/clients/add-client)
      '';
    };
    enableGrafanaDashboard = lib.mkEnableOption "Grafana Dashboard";
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
      example = {
        PANGOLIN_ENDPOINT = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_ID = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_METRICS_PROMETHEUS_ENABLED = "true";
        LOG_LEVEL = "INFO";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = lib.mkMerge [
      (import ./settings.nix)
      (lib.mkIf config.nps.stacks.traefik.enable {
        customDNS.mapping.${config.nps.stacks.traefik.domain} = ip;
      })
      (lib.mkIf cfg.enablePrometheusExport {
        prometheus.enable = true;
      })
    ];
    nps.stacks.monitoring.grafana = lib.mkIf cfg.enableGrafanaDashboard {
      dashboards = [./grafana_dashboard.json];
      settings.panels.disable_sanitize_html = true;
    };
    nps.stacks.monitoring.prometheus.settings = lib.mkIf cfg.enablePrometheusExport {
      scrape_configs = [
        {
          job_name = "${name}";
          honor_timestamps = true;
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [{targets = [(name + ":2112")];}];
        }
      ];
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/fosrl/newt:1.6.0";
      volumes = [
        "${cfg.settings}:/app/config.yml"
      ];

      extraEnv = cfg.extraEnv;

      port = 2112;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "pangolin-newt";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:pangolin-newt";
      };
    };
  };
}
