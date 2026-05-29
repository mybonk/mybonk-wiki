---
layout: default
title: Workshop 7
nav_order: 8
---

# Workshop 7: Container Monitoring with Prometheus and Grafana

## Overview

This workshop adds a real-time monitoring dashboard to the container infrastructure built in [Workshop 6](../workshop-6/). You will enable a **Prometheus + Grafana** stack — the industry-standard observability pair — without writing any new Nix files. All the configuration already lives in workshop-6, commented out and waiting.

**What you will see in the dashboard:**
- CPU usage per container
- Memory consumption and available RAM
- Disk I/O and filesystem usage
- Network traffic (bytes in/out)
- Systemd service states per container

**How it works:**

```
┌─────────────────────────────────────────────────────────────┐
│  Host                                                        │
│                                                              │
│  Grafana :3000 ──── queries ──→ Prometheus :9090            │
│                                       │                      │
│                              scrapes every 15 s             │
│                            ┌──────────┴──────────┐          │
│  container1 :9100      container2 :9100            │         │
│  node_exporter         node_exporter              │         │
└─────────────────────────────────────────────────────────────┘
```

Each container runs **node_exporter**, which exposes hundreds of metrics on port 9100. Prometheus pulls those metrics on a schedule and stores them. Grafana reads from Prometheus and renders the dashboard.

**Prerequisites:**
- [Workshop 6](../workshop-6/) — containers running, host bridge and NAT in place

**No new files** — this workshop only uncomments existing blocks in workshop-6.

---

## Part 1: Enable node_exporter in Each Container

Open `workshop-6/configuration.nix` and uncomment the monitoring block near the bottom:

```nix
services.prometheus.exporters.node = {
  enable = true;
  enabledCollectors = [ "systemd" ];
  port = 9100;
};
```

Update both containers to apply the change:

```bash
cd workshop-6
sudo nixos-container update container1 --flake .#container1
sudo nixos-container update container2 --flake .#container2
```

Verify node_exporter is listening inside each container:

```bash
sudo nixos-container run container1 -- curl -s http://127.0.0.1:9100/metrics | head -5
sudo nixos-container run container2 -- curl -s http://127.0.0.1:9100/metrics | head -5
```

You should see lines starting with `# HELP` and `# TYPE` followed by metric values.

---

## Part 2: Find Your Container IPs

Prometheus needs the IP address of each container to scrape it. Containers use DHCP, so look up their current addresses:

```bash
sudo nixos-container run container1 -- ip addr show host0 | grep "inet "
sudo nixos-container run container2 -- ip addr show host0 | grep "inet "
```

Example output:
```
inet 10.100.0.73/24 brd 10.100.0.255 scope global host0
inet 10.100.0.91/24 brd 10.100.0.255 scope global host0
```

Note these IPs — you will need them in the next step.

---

## Part 3: Enable Prometheus and Grafana on the Host

Open `workshop-6/host-setup.nix` and uncomment the monitoring block. Before saving, replace the placeholder IPs with the ones you found above:

```nix
services.prometheus = {
  enable = true;
  port = 9090;
  scrapeConfigs = [
    {
      job_name = "containers";
      static_configs = [
        {
          targets = [
            "10.100.0.73:9100"   # container1 — your actual IP here
            "10.100.0.91:9100"   # container2 — your actual IP here
          ];
        }
      ];
    }
  ];
};

services.grafana = {
  enable = true;
  settings = {
    server = {
      http_addr = "0.0.0.0";
      http_port = 3000;
    };
    security = {
      admin_user = "admin";
      admin_password = "admin";
    };
  };
  provision = {
    enable = true;
    datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
        isDefault = true;
      }
    ];
  };
};

# Open ports if the host firewall is enabled
networking.firewall.allowedTCPPorts = [ 3000 9090 ];
```

Apply to the host:

```bash
sudo nixos-rebuild switch
```

Confirm both services are running:

```bash
systemctl status prometheus
systemctl status grafana
```

Both should show `active (running)`.

---

## Part 4: Access the Dashboard

### Open Grafana

Find your host's IP address (the machine running the containers):

```bash
ip route get 1 | awk '{print $7; exit}'
```

Open a browser and navigate to:

```
http://<host-ip>:3000
```

Log in with **admin / admin**. Grafana will ask you to set a new password — you can skip this for a lab environment.

> If you are on the same machine as the host, use `http://localhost:3000`.  
> If you are accessing over Tailscale, use the Tailscale IP shown by `tailscale ip -4`.

### Verify the Prometheus Data Source

The data source is provisioned automatically. Confirm it is connected:

1. Click the menu (☰) → **Connections** → **Data sources**
2. Click **Prometheus**
3. Scroll down and click **Save & test**

You should see **"Successfully queried the Prometheus API"**.

### Check Prometheus Targets

Open Prometheus directly to confirm it is scraping your containers:

```
http://<host-ip>:9090/targets
```

Both `container1` and `container2` should appear with state **UP**. If a target shows **DOWN**, check the IP addresses in `host-setup.nix`.

### Import a Dashboard

The fastest way to get a full dashboard is to import a pre-built one from grafana.com:

1. Click **☰** → **Dashboards** → **New** → **Import**
2. Enter dashboard ID **`1860`** in the "Import via grafana.com" field
3. Click **Load**
4. Under **Prometheus**, select **Prometheus** (the data source you just verified)
5. Click **Import**

Dashboard **1860** is "Node Exporter Full" — one of the most popular community dashboards. It shows detailed CPU, memory, disk, and network graphs with per-host filtering.

At the top of the dashboard, use the **job** and **instance** dropdowns to switch between `container1` and `container2`.

---

## What You Are Seeing

| Panel | What it measures |
|-------|-----------------|
| CPU Busy | Percentage of CPU time not idle |
| RAM Used | Resident memory in use vs total |
| Root FS Used | Disk space consumed on `/` |
| Network Traffic | Bytes received and transmitted per second |
| Systemd Services | Failed / active service count (requires `systemd` collector) |

Metrics are stored in Prometheus with 15-day retention by default. The graphs show history from the moment you enabled scraping.

---

## Troubleshooting

**Grafana blank / not loading:**
```bash
systemctl status grafana
journalctl -u grafana -n 30
```

**Prometheus targets show DOWN:**

Check that node_exporter is reachable from the host:
```bash
curl http://<container-ip>:9100/metrics | head -3
```

If that times out, verify the container's firewall is off (`networking.firewall.enable = false` in configuration.nix) and that the container is running.

**"Data source connected but no labels received":**

Prometheus may not have scraped yet. Wait 30 seconds and retry, or check:
```bash
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

**IP changed after container restart:**

DHCP leases can change. Re-run the IP lookup commands from Part 2, update the targets in `host-setup.nix`, and rebuild the host. To avoid this, assign static IPs to containers via the dnsmasq `dhcp-host` option.

---

## References

- [Workshop 6: Manage NixOS Containers via CLI](../workshop-6/)
- [NixOS — Prometheus module](https://nixos.wiki/wiki/Prometheus)
- [NixOS — Grafana module](https://nixos.wiki/wiki/Grafana)
- [Node Exporter Full dashboard (ID 1860)](https://grafana.com/grafana/dashboards/1860)
- [Prometheus — Getting started](https://prometheus.io/docs/prometheus/latest/getting_started/)
