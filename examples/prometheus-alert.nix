{
  nps.stacks = {
    # We will receive notifications through ntfy
    ntfy.enable = true;

    monitoring = {
      enable = true;

      # Prometheus alert rules.
      # Fire when CPU usage is >90% for 20 minutes or RAM usage is >85%
      # Alertmanager will handle alerts
      prometheus.rules.groups = let
        cpuThresh = 90;
        ramThresh = 85;
      in [
        {
          name = "resource.usage";
          rules = [
            {
              alert = "HighCpuUsage";
              expr = ''100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > ${toString cpuThresh}'';
              for = "20m";
              labels = {
                severity = "warning";
              };
              annotations = {
                summary = "High CPU usage";
                description = "CPU usage is above ${toString cpuThresh}% (current value: {{ $value }}%)";
              };
            }
            {
              alert = "HighRamUsage";
              expr = ''(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > ${toString ramThresh}'';
              labels = {
                severity = "warning";
              };
              annotations = {
                summary = "High RAM usage";
                description = "RAM usage is above ${toString ramThresh}% (current value: {{ $value }}%)";
              };
            }
          ];
        }
      ];

      # Handle Prometheus alerts and forward them to ntfy
      alertmanager = {
        enable = true;
        ntfy = {
          enable = true;
          settings.ntfy.notification.topic = "monitoring";
        };
      };
    };
  };
}
