# Prometheus, Grafana & Alertmanager Monitoring Stack

A production-ready Docker-based monitoring solution combining **Prometheus** (metrics collection), **Alertmanager** (alert management with Telegram notifications), and **Grafana** (metrics visualization). This repository provides an integrated observability stack optimized for monitoring containerized infrastructure with support for multiple data sources.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Components](#components)
3. [Prerequisites](#prerequisites)
4. [Repository Structure](#repository-structure)
5. [Installation & Deployment](#installation--deployment)
6. [Configuration Guide](#configuration-guide)
7. [Service Endpoints](#service-endpoints)
8. [Monitoring Setup](#monitoring-setup)
9. [Alert Rules & Management](#alert-rules--management)
10. [Telegram Notifications Setup](#telegram-notifications-setup)
11. [Data Collection](#data-collection)
12. [Troubleshooting](#troubleshooting)
13. [Security Considerations](#security-considerations)
14. [Operational Procedures](#operational-procedures)

---

## 🏗️ Architecture Overview

This monitoring stack is designed with a **network_mode: host** configuration, enabling direct access to host system metrics and simplified networking. The architecture consists of:

```
┌─────────────────────────────────────────────────────┐
│                   Host System                        │
├─────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ Prometheus   │──│ Alertmanager │  │  Grafana   │ │
│  │ :9090        │  │ :9093        │  │  :3000     │ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
│        ↓                ↓                    ↓        │
│  ┌──────────────┐  ┌────────────────┐  ┌──────────┐  │
│  │  cAdvisor    │  │ Telegram API   │  │Prometheus│  │
│  │ :8080        │  │                │  │DataSource│  │
│  └──────────────┘  └────────────────┘  └──────────┘  │
│        ↑                                       ↑      │
└────────┼───────────────────────────────────────┼─────┘
         │                                       │
    ┌────┴─────────┐                    ┌────────┴─────┐
    │ Remote Hosts  │                    │ Node Exporters│
    │ :9100, :9153  │                    │ :9100, :8080  │
    └───────────────┘                    └───────────────┘
```

**Key Design Decisions:**
- **Host Networking**: Direct host access eliminates network overlays and port remapping
- **Persistent Volumes**: Named volumes for data durability
- **Secrets Management**: Docker Secrets for sensitive credentials
- **Multi-Source Scraping**: Configured for distributed monitoring

---

## 🔧 Components

### Prometheus (v3.5.0)
- **Role**: Time-series metrics database and alerting engine
- **Port**: 9090
- **Features**:
  - 30-day data retention (`--storage.tsdb.retention.time=30d`)
  - Dynamic hot-reload configuration (`--web.enable-lifecycle`)
  - Multi-job scraping with 15s default interval

### Alertmanager (v0.28.1)
- **Role**: Alert routing, grouping, and notification dispatching
- **Port**: 9093
- **Features**:
  - Alert grouping by alertname and instance
  - 5-minute resolution timeout
  - Telegram integration for instant notifications
  - Alert suppression and silencing capabilities

### Grafana (v12.0.2)
- **Role**: Metrics visualization and dashboard management
- **Port**: 3000
- **Features**:
  - Secure admin authentication via secrets file
  - Anonymous access disabled
  - Automatic datasource provisioning
  - Dashboard templating support

### cAdvisor (v0.49.1)
- **Role**: Container metrics collection
- **Port**: 8080
- **Features**:
  - Docker daemon statistics
  - Container resource consumption metrics
  - No performance overhead with `privileged: false`

---

## 📦 Prerequisites

### System Requirements
```bash
# Minimum specifications:
- CPU: 2 cores
- Memory: 2 GB RAM
- Disk: 20 GB (depends on retention policy and number of targets)
- OS: Linux with Docker support (kernel 4.0+)

# Recommended for production:
- CPU: 4+ cores
- Memory: 4+ GB RAM
- Disk: 50+ GB with SSD storage
```

### Software Requirements
```bash
# Verify versions
$ docker --version
Docker version 20.10+ required

$ docker-compose --version
Docker Compose version 1.29+ required

$ git --version
Git version 2.30+ required
```

### Network Requirements
- TCP Port 9090 (Prometheus)
- TCP Port 9093 (Alertmanager)
- TCP Port 3000 (Grafana)
- TCP Port 8080 (cAdvisor)
- Outbound HTTPS to Telegram API (api.telegram.org)

### Installation Verification
```bash
docker run --rm hello-world
docker-compose version
git --version
```

---

## 📁 Repository Structure

```
prometheus-grafana/
│
├── docker-compose.yml                  # Service orchestration configuration
│
├── install-node-exporter.sh            # Automated Node Exporter installation script
│
├── prometheus/                         # Prometheus configuration directory
│   ├── prometheus.yml                  # Main Prometheus configuration
│   │   ├── Global settings (scrape/evaluation intervals)
│   │   ├── Alert rule file references
│   │   ├── Alertmanager target configuration
│   │   └── Scrape job definitions
│   │
│   └── alert_rules.yml                 # Alert rule definitions
│       ├── HostDown alert (critical severity)
│       └── HighCPU alert (warning severity)
│
├── alertmanager/                       # Alertmanager configuration directory
│   └── alertmanager.yml                # Alert routing and receiver configuration
│       ├── Telegram receiver configuration
│       ├── Alert grouping strategy
│       └── Message formatting rules
│
├── grafana/                            # Grafana configuration directory
│   └── provisioning/                   # Auto-provisioning configurations
│       └── datasources/
│           └── datasource.yml          # Prometheus datasource definition
│
├── secrets/                            # Sensitive credentials (Docker Secrets)
│   ├── grafana_admin_password          # Grafana admin authentication
│   ├── telegram_bot_token              # Telegram Bot API token
│   └── telegram_chat_id                # Telegram destination chat ID
│
└── README.md                           # This documentation file
```

### Configuration Hierarchy
```
Environment Variables
    ↓
docker-compose.yml (service definitions)
    ↓
prometheus.yml (scrape configs) → alert_rules.yml (alert conditions)
    ↓
alertmanager.yml (alert routing) → Telegram API
    ↓
datasource.yml (Grafana data binding)
    ↓
Volumes (prometheus_data, grafana_data, alertmanager_data)
```

---

## 🚀 Installation & Deployment

### Step 1: Clone Repository
```bash
git clone https://github.com/nahid-devops2021/prometheus-grafana.git
cd prometheus-grafana
```

### Step 2: Create Data Directories
```bash
# Create persistent volume directories with proper permissions
mkdir -p prometheus_data grafana_data alertmanager_data
chmod 755 prometheus_data grafana_data alertmanager_data

# Verify creation
ls -la | grep data
```

### Step 3: Configure Secrets
```bash
# Grafana admin password (8+ characters recommended)
echo "YourSecurePassword123" > secrets/grafana_admin_password
chmod 600 secrets/grafana_admin_password

# Telegram Bot Token (obtain from @BotFather on Telegram)
echo "YOUR_BOT_TOKEN_HERE" > secrets/telegram_bot_token
chmod 600 secrets/telegram_bot_token

# Telegram Chat ID (numeric ID of target chat)
echo "YOUR_CHAT_ID_HERE" > secrets/telegram_chat_id
chmod 600 secrets/telegram_chat_id
```

### Step 4: Start Services
```bash
# Build and start all services in daemon mode
docker-compose up -d

# Verify all services are running
docker-compose ps

# Expected output:
# NAME              STATUS              PORTS
# prometheus        Up 2 minutes
# alertmanager      Up 2 minutes
# grafana           Up 2 minutes
# cadvisor          Up 2 minutes
```

### Step 5: Verify Service Health
```bash
# Check Prometheus is accepting metrics
curl -s http://localhost:9090/api/v1/status/runtimeinfo | jq .

# Check Alertmanager status
curl -s http://localhost:9093/api/v1/status | jq .

# Check Grafana is running
curl -s http://localhost:3000/api/health | jq .

# Verify container logs for errors
docker-compose logs --tail=20 prometheus
docker-compose logs --tail=20 alertmanager
docker-compose logs --tail=20 grafana
```

---

## ⚙️ Configuration Guide

### Prometheus Configuration (`prometheus/prometheus.yml`)

**Global Settings:**
```yaml
global:
  scrape_interval: 15s           # Default metric collection interval
  evaluation_interval: 15s       # Alert rule evaluation frequency
  external_labels:
    environment: production      # Label added to all metrics
    monitor: docker-monitoring   # Monitoring instance identifier
```

**Alert Integration:**
```yaml
rule_files:
  - alert_rules.yml             # Load alert rules from file

alerting:
  alertmanagers:
    - static_configs:
      - targets: ["localhost:9093"]  # Alertmanager endpoint
```

**Scrape Configurations:**

The repository is configured to monitor multiple data sources:

```yaml
scrape_configs:
  # 1. Self-monitoring (Prometheus itself)
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  # 2. CoreDNS monitoring (DNS Server at 192.168.0.33)
  - job_name: "coredns"
    scrape_interval: 5s
    static_configs:
      - targets: ["192.168.0.33:9153"]

  # 3. Node Exporter monitoring (Host metrics)
  - job_name: node_exporter
    scrape_interval: 5s
    static_configs:
      # Grafana Server metrics
      - targets: ["192.168.0.40:9100"]
        labels:
          server: "Grafana-Server"
          environment: "production"
      
      # DNS Server metrics
      - targets: ["192.168.0.33:9100"]
        labels:
          server: "DNS-Server"
          environment: "production"

  # 4. Container monitoring (cAdvisor)
  - job_name: cadvisor
    scrape_interval: 5s
    static_configs:
      - targets:
        - "192.168.0.40:8080"    # Grafana host
        - "192.168.0.33:8080"    # DNS host
```

**Adding New Scrape Targets:**
```yaml
- job_name: "my_new_service"
  scrape_interval: 30s            # Custom interval (optional)
  static_configs:
    - targets: ["192.168.x.x:PORT"]
      labels:
        service: "my_service"
        tier: "application"
```

**Apply Configuration Changes:**
```bash
# Edit prometheus.yml
nano prometheus/prometheus.yml

# Hot-reload configuration (no downtime)
curl -X POST http://localhost:9090/-/reload

# Or restart the container
docker-compose restart prometheus
```

### Alert Rules Configuration (`prometheus/alert_rules.yml`)

**Defined Alerts:**

1. **HostDown Alert** (Critical)
```yaml
- alert: HostDown
  expr: up == 0                  # Target unreachable
  for: 1m                        # Must persist for 1 minute
  labels:
    severity: critical           # Alert severity level
  annotations:
    description: "{{ $labels.instance }} is down"
```

2. **HighCPU Alert** (Warning)
```yaml
- alert: HighCPU
  expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
  for: 5m                        # Alert if CPU >80% for 5 minutes
  labels:
    severity: warning
  annotations:
    description: "CPU usage above 80%"
```

**Adding Custom Alert Rules:**
```yaml
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
  for: 3m
  labels:
    severity: warning
  annotations:
    summary: "High memory usage on {{ $labels.instance }}"
    description: "Memory usage is {{ $value | humanizePercentage }}"
```

**Testing Alert Expressions:**
```bash
# Query alert expression in Prometheus UI
# http://localhost:9090/graph
# Enter: up == 0

# Or via CLI
curl 'http://localhost:9090/api/v1/query?query=up'
```

### Alertmanager Configuration (`alertmanager/alertmanager.yml`)

**Global Configuration:**
```yaml
global:
  resolve_timeout: 5m  # Auto-resolve alerts after 5 minutes without trigger
```

**Alert Routing:**
```yaml
route:
  receiver: telegram-notifications    # Default receiver
  group_by: ['alertname', 'instance'] # Group alerts by name and instance
  group_wait: 30s                     # Wait before sending group
  group_interval: 5m                  # Resend every 5 minutes
  repeat_interval: 4h                 # Remind every 4 hours
```

**Telegram Receiver Configuration:**
```yaml
receivers:
  - name: telegram-notifications
    telegram_configs:
      - bot_token_file: /run/secrets/telegram_bot_token
        chat_id_file: /run/secrets/telegram_chat_id
        api_url: https://api.telegram.org
        parse_mode: HTML
        send_resolved: true
        message: |
          <b>{{ if eq .Status "firing" }}🔥 FIRING{{ else }}✅ RESOLVED{{ end }}: 
            {{ .CommonLabels.alertname }}</b>
          
          Instance: {{ .Labels.instance }}
          Server: {{ .Labels.server }}
          Severity: {{ .Labels.severity }}
          Description: {{ .Annotations.description }}
          Started: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
```

**Adding Additional Receivers:**
```yaml
receivers:
  - name: slack-notifications
    slack_configs:
      - api_url: YOUR_SLACK_WEBHOOK_URL
        channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ .Alerts.Firing | len }} firing alerts'
  
  - name: email-notifications
    email_configs:
      - to: ops-team@example.com
        from: alerts@example.com
        smarthost: smtp.gmail.com:587
        auth_username: your-email@gmail.com
        auth_password: your-app-password
```

**Validate Configuration:**
```bash
docker-compose exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

---

## 🔗 Service Endpoints

### Web UI Access

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| Prometheus | http://localhost:9090 | 9090 | Metrics queries, target health, alerts status |
| Alertmanager | http://localhost:9093 | 9093 | Alert management, silencing, routing inspection |
| Grafana | http://localhost:3000 | 3000 | Dashboard visualization and management |
| cAdvisor | http://localhost:8080 | 8080 | Container metrics (raw metrics page) |

### API Endpoints

**Prometheus API:**
```bash
# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'

# Query time-range data
curl 'http://localhost:9090/api/v1/query_range?query=up&start=<UNIX_TS>&end=<UNIX_TS>&step=60s'

# List all targets
curl 'http://localhost:9090/api/v1/targets'

# Check configuration
curl 'http://localhost:9090/api/v1/status/config' | jq .
```

**Alertmanager API:**
```bash
# List all alerts
curl 'http://localhost:9093/api/v1/alerts'

# Create alert silence (example: 1 hour silence)
curl -X POST 'http://localhost:9093/api/v1/silences' \
  -H 'Content-Type: application/json' \
  -d '{
    "matchers": [{"name": "alertname", "value": "HighCPU"}],
    "duration": "1h",
    "createdBy": "admin"
  }'

# List silences
curl 'http://localhost:9093/api/v1/silences'
```

---

## 📊 Monitoring Setup

### Initial Grafana Configuration

**Login & Change Password:**
1. Navigate to http://localhost:3000
2. Login with:
   - Username: `admin`
   - Password: (from `secrets/grafana_admin_password`)
3. Change password immediately (Profile → Change Password)

**Verify Data Source:**
1. Configuration → Data Sources
2. Verify "Prometheus" is listed and showing "green" status
3. URL should be: `http://localhost:9090` (auto-filled via `datasource.yml`)

**Create Your First Dashboard:**
```
1. Click "+" → Dashboard → Add panel
2. Select Prometheus as datasource
3. Enter query: rate(prometheus_http_requests_total[5m])
4. Set visualization: Graph
5. Save Dashboard
```

### Available Metrics

**Prometheus Internal Metrics:**
```promql
# Request rate
rate(prometheus_http_requests_total[5m])

# Scrape duration
histogram_quantile(0.99, rate(prometheus_tsdb_compaction_duration_seconds_bucket[5m]))

# Time series cardinality
prometheus_tsdb_metric_chunks_created_total
```

**Node Exporter Metrics (from 192.168.0.40, 192.168.0.33):**
```promql
# CPU utilization
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk usage
node_filesystem_avail_bytes / node_filesystem_size_bytes * 100

# Network throughput
rate(node_network_receive_bytes_total[5m])
```

**cAdvisor Metrics:**
```promql
# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory usage
container_memory_usage_bytes

# Container network I/O
rate(container_network_receive_bytes_total[5m])
```

---

## 🚨 Alert Rules & Management

### Alert Lifecycle

```
Condition Met (Prometheus)
    ↓
PENDING State (for: duration)
    ↓
FIRING State (alert.rules.yml threshold exceeded)
    ↓
Alertmanager (receives alert)
    ↓
Grouping & Deduplication
    ↓
Telegram Notification
    ↓
RESOLVED (when condition clears) or INHIBITED (by rules)
```

### Alert Status Tracking

**View Firing Alerts:**
```bash
# Via Prometheus UI: http://localhost:9090/alerts
# Via Alertmanager UI: http://localhost:9093

# Via API:
curl 'http://localhost:9093/api/v1/alerts?status=firing'
```

**Query Alert Status:**
```promql
# Count firing alerts
count(ALERTS{alertstate="firing"})

# Show alert details
ALERTS{alertstate="firing"}
```

### Managing Alerts

**Silence an Alert:**
```bash
# Web UI: Alertmanager → Silences → New Silence
# Duration: 1h, Matchers: alertname="HighCPU"

# Or via API:
curl -X POST 'http://localhost:9093/api/v1/silences' \
  -H 'Content-Type: application/json' \
  -d '{
    "matchers": [
      {"name": "alertname", "value": "HighCPU", "isRegex": false}
    ],
    "duration": "1h",
    "comment": "Planned maintenance window",
    "createdBy": "admin"
  }'
```

**Reload Alert Rules:**
```bash
# Hot-reload without restarting
curl -X POST http://localhost:9090/-/reload

# Or restart Prometheus
docker-compose restart prometheus
```

---

## 📲 Telegram Notifications Setup

### Prerequisites
- Telegram account
- Telegram Desktop or Mobile app

### Step 1: Create Bot with @BotFather

```
1. Open Telegram and search for @BotFather
2. Send message: /start
3. Send message: /newbot
4. Follow prompts:
   - Give your bot a name (e.g., "Prometheus Alerts")
   - Give your bot a username (e.g., "prometheus_alerts_bot")
5. Copy the Bot Token (looks like: 123456:ABC-DEF...)
```

### Step 2: Get Chat ID

**Option A: Using Bot Message**
```
1. Message your bot created in Step 1
2. Visit: https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
3. Look for "chat"→"id" in the JSON response
4. Copy the numeric ID
```

**Option B: Using Web Helper**
```
1. Message @userinfobot in Telegram
2. It will reply with your user ID
3. Use this ID as chat_id
```

### Step 3: Configure Secrets
```bash
# Store Bot Token
echo "123456:ABC-DEF..." > secrets/telegram_bot_token
chmod 600 secrets/telegram_bot_token

# Store Chat ID
echo "987654321" > secrets/telegram_chat_id
chmod 600 secrets/telegram_chat_id
```

### Step 4: Test Alert Delivery
```bash
# Restart Alertmanager to apply secrets
docker-compose restart alertmanager

# Check logs for configuration
docker-compose logs alertmanager | grep -i telegram

# Trigger test alert
curl -X POST 'http://localhost:9090/api/v1/alerts' \
  -H 'Content-Type: application/json' \
  -d '[{
    "labels": {"alertname": "TestAlert", "severity": "warning"},
    "annotations": {"description": "This is a test alert"}
  }]'

# Monitor Alertmanager logs
docker-compose logs -f alertmanager
```

### Telegram Message Format
```
🔥 FIRING: HighCPU
Instance: 192.168.0.40:9100
Server: Grafana-Server
Severity: warning
Summary: CPU usage above 80%
Description: CPU usage above 80%
Started: 2024-01-15 14:32:05
```

### Troubleshooting Telegram Integration

**Issue: No messages received**
```bash
# Verify bot token is readable
cat secrets/telegram_bot_token

# Check Alertmanager can connect to Telegram
docker-compose exec alertmanager sh -c 'curl -I https://api.telegram.org'

# View Alertmanager logs
docker-compose logs alertmanager | tail -50

# Verify chat ID is valid (send message to bot first)
curl "https://api.telegram.org/bot$(cat secrets/telegram_bot_token)/getUpdates"
```

**Issue: Telegram API errors**
```
Error: "Unauthorized" - Check bot token in secrets/telegram_bot_token
Error: "Bad Request" - Verify chat_id is numeric and valid
Error: "Not Found" - Bot may have been disabled, recreate with @BotFather
```

---

## 🎯 Data Collection

### Node Exporter Installation

Deploy Node Exporter to monitored hosts using the provided script:

```bash
# Copy script to remote host
scp install-node-exporter.sh user@192.168.0.40:/tmp/

# Execute with sudo (script requires root)
ssh user@192.168.0.40 'sudo bash /tmp/install-node-exporter.sh'

# Verify installation
ssh user@192.168.0.40 'curl http://localhost:9100/metrics | head -20'
```

**What the Script Does:**
1. Detects system architecture (x86_64, ARM64, ARMv7)
2. Creates `node_exporter` system user
3. Downloads Node Exporter v1.9.1
4. Installs binary to `/usr/local/bin/node_exporter`
5. Creates systemd service
6. Enables firewall rules (firewall-cmd, ufw)
7. Starts service and shows metrics endpoint

**Collector Flags Enabled:**
```
--collector.systemd       # systemd service status
--collector.processes     # Process metrics
--collector.cpu           # CPU statistics
--collector.meminfo       # Memory information
--collector.filesystem    # Disk usage
--collector.diskstats     # Disk I/O
--collector.netdev        # Network interface stats
--collector.netstat       # Network protocol stats
--collector.loadavg       # Load average
--collector.uname         # System information
--collector.time          # System time
--collector.textfile      # Custom metrics from scripts
```

**Verify Node Exporter Service:**
```bash
# Check service status
systemctl status node_exporter

# View metrics endpoint
curl http://192.168.0.40:9100/metrics | head -20

# Monitor metrics in real-time
watch -n 1 'curl -s http://192.168.0.40:9100/metrics | grep node_'
```

### cAdvisor Metrics Collection

cAdvisor runs as a Docker container and automatically collects container metrics:

```bash
# cAdvisor metrics endpoint
curl http://localhost:8080/metrics | head -20

# Check running containers
curl http://localhost:8080/api/v1/containers/

# Specific container metrics
curl http://localhost:8080/api/v1.3/subcontainers/docker/
```

### CoreDNS Metrics

CoreDNS on 192.168.0.33:9153 exposes metrics about:
- Query count and latency
- Cache hit/miss rates
- DNSSEC validation status
- Zone transfer statistics

```bash
curl http://192.168.0.33:9153/metrics | grep coredns
```

---

## 🛠️ Troubleshooting

### Service Health Checks

**Prometheus Not Scraping Targets**
```bash
# Check target status
curl http://localhost:9090/api/v1/targets | jq .

# Check specific target
curl 'http://localhost:9090/api/v1/targets?state=any' | jq '.data.activeTargets[]'

# Look for errors
docker-compose logs prometheus | grep -i "error\|fail"
```

**No Data in Grafana**
```bash
# Verify datasource connectivity
curl -s http://localhost:3000/api/datasources | jq .

# Check Prometheus has data
curl 'http://localhost:9090/api/v1/query?query=up'

# View Grafana logs
docker-compose logs grafana | tail -50

# Restart datasource service
docker-compose restart grafana
```

**Alerts Not Triggering**
```bash
# Verify alert rules loaded
curl http://localhost:9090/api/v1/rules | jq .

# Test alert expression manually
curl 'http://localhost:9090/api/v1/query?query=up==0'

# Check rule file syntax
docker-compose exec prometheus promtool check rules /etc/prometheus/alert_rules.yml
```

**Alertmanager Not Sending Notifications**
```bash
# Check Alertmanager configuration
docker-compose exec alertmanager amtool check-config

# View Telegram receiver config
docker-compose exec alertmanager amtool config receivers

# Monitor Alertmanager logs
docker-compose logs -f alertmanager

# Check if alerts are reaching Alertmanager
curl http://localhost:9093/api/v1/alerts

# Test Telegram connectivity from container
docker-compose exec alertmanager curl https://api.telegram.org/
```

**Port Conflicts**
```bash
# Check which process is using the port
lsof -i :9090
lsof -i :9093
lsof -i :3000
lsof -i :8080

# Kill process or change port in docker-compose.yml
kill -9 <PID>
```

### Container Restart Issues

```bash
# View all container logs
docker-compose logs -f

# Restart specific service
docker-compose restart prometheus

# Full restart (recreate containers)
docker-compose down
docker-compose up -d

# Remove all data and start fresh
docker-compose down -v
docker-compose up -d
```

### Performance Issues

**High Memory Usage:**
```bash
# Check retention period (longer = more memory)
grep "retention.time" docker-compose.yml

# Reduce retention (keep last 7 days instead of 30)
# Edit docker-compose.yml:
# - --storage.tsdb.retention.time=7d

# Restart Prometheus
docker-compose restart prometheus
```

**High CPU Usage:**
```bash
# Check scrape interval and number of targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Increase scrape intervals in prometheus.yml
# Change: scrape_interval: 5s → scrape_interval: 30s

# Reduce number of enabled collectors in Node Exporter
# Edit install-node-exporter.sh and remove unnecessary collectors
```

**Disk Space Issues:**
```bash
# Check volume usage
du -sh prometheus_data grafana_data alertmanager_data

# Reduce retention period
docker-compose exec prometheus \
  promtool query instant 'prometheus_tsdb_symbol_table_size_bytes'

# Compact TSDB
docker-compose exec prometheus \
  curl -X POST http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]='{job="old_job"}'
```

---

## 🔐 Security Considerations

### Production Deployment Checklist

- [ ] Change all default passwords
  ```bash
  echo "RandomString$(openssl rand -base64 32)" > secrets/grafana_admin_password
  ```

- [ ] Use reverse proxy with SSL/TLS
  ```nginx
  # Example Nginx configuration
  server {
    listen 443 ssl;
    server_name monitoring.example.com;
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    
    location /prometheus/ {
      proxy_pass http://localhost:9090;
      auth_basic "Prometheus";
      auth_basic_user_file /etc/nginx/htpasswd;
    }
    
    location /alertmanager/ {
      proxy_pass http://localhost:9093;
      auth_basic "Alertmanager";
      auth_basic_user_file /etc/nginx/htpasswd;
    }
    
    location /grafana/ {
      proxy_pass http://localhost:3000;
    }
  }
  ```

- [ ] Restrict network access
  ```bash
  # Only allow internal networks to Prometheus/Alertmanager
  # Edit docker-compose.yml to use specific networks instead of host mode
  ```

- [ ] Encrypt secrets
  ```bash
  chmod 600 secrets/*
  sudo chown root:root secrets/
  ```

- [ ] Regular backups
  ```bash
  # Backup Prometheus data
  docker-compose exec -T prometheus tar czf - /prometheus | \
    gzip > prometheus_backup_$(date +%Y%m%d).tar.gz
  
  # Backup Grafana dashboards
  docker cp grafana:/var/lib/grafana grafana_backup_$(date +%Y%m%d)
  ```

- [ ] Monitor logs for suspicious activity
  ```bash
  docker-compose logs | grep -i "unauthorized\|error\|failed"
  ```

### Network Security

```yaml
# Use bridge network instead of host mode in production
services:
  prometheus:
    networks:
      - monitoring
    
  grafana:
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Credential Management

- Never commit secrets to Git
- Use Docker Secrets for credentials
- Rotate bot tokens regularly
- Use `.gitignore` for secret files
```bash
echo "secrets/" >> .gitignore
echo "prometheus_data/" >> .gitignore
echo "grafana_data/" >> .gitignore
```

---

## 📋 Operational Procedures

### Daily Operations

**Health Check:**
```bash
# Verify all services running
docker-compose ps

# Check for errors in logs
docker-compose logs | tail -100 | grep -i error

# Verify targets are healthy
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="down")'
```

**Metric Validation:**
```bash
# Count unique metrics
curl -s http://localhost:9090/api/v1/labels/__name__ | jq '.data | length'

# Check data freshness
curl -s 'http://localhost:9090/api/v1/query?query=time()'
```

### Weekly Maintenance

**Backup Procedure:**
```bash
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

# Backup all volumes
docker-compose stop
tar czf prometheus_backup_${BACKUP_DATE}.tar.gz prometheus_data/
tar czf grafana_backup_${BACKUP_DATE}.tar.gz grafana_data/
tar czf alertmanager_backup_${BACKUP_DATE}.tar.gz alertmanager_data/
docker-compose start

# Archive configurations
tar czf configs_backup_${BACKUP_DATE}.tar.gz \
  prometheus/ grafana/ alertmanager/ secrets/

# Transfer to remote location
scp -r *_${BACKUP_DATE}.tar.gz backup@backup-server:/mnt/backups/
```

**Alert Tuning:**
```bash
# Review false positive alerts
curl 'http://localhost:9093/api/v1/alerts?status=firing' | jq .

# Adjust thresholds if needed
nano prometheus/alert_rules.yml
curl -X POST http://localhost:9090/-/reload

# Test modified rules
curl 'http://localhost:9090/api/v1/query?query=HighCPU'
```

### Monthly Review

**Capacity Planning:**
```bash
# Monitor disk growth
du -sh prometheus_data/
# If growing too fast, reduce retention period

# Review metric cardinality
curl -s 'http://localhost:9090/api/v1/labels/__name__' | jq '.data | length'

# Identify high-cardinality metrics
curl -s 'http://localhost:9090/api/v1/series?match[]=.*' | \
  jq -r '.[].metric | keys[]' | sort | uniq -c | sort -rn | head -20
```

**Performance Optimization:**
```bash
# Check Prometheus memory usage
docker stats prometheus

# Review query performance
curl 'http://localhost:9090/api/v1/status/config' | jq .

# Adjust scrape intervals if needed
nano prometheus/prometheus.yml
```

### Upgrade Procedure

```bash
# Check for new versions
docker pull prom/prometheus
docker pull prom/alertmanager
docker pull grafana/grafana
docker pull gcr.io/cadvisor/cadvisor

# Update docker-compose.yml with new versions
nano docker-compose.yml

# Stop services gracefully
docker-compose stop

# Backup current data
tar czf backup_pre_upgrade.tar.gz prometheus_data/ grafana_data/ alertmanager_data/

# Start with new versions
docker-compose up -d

# Verify functionality
curl http://localhost:9090/api/v1/status/runtimeinfo
curl http://localhost:3000/api/health
```

---

## 📚 Additional Resources

### Official Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [cAdvisor Metrics](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md)

### PromQL Queries
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Node Exporter Metrics Reference](https://github.com/prometheus/node_exporter)

### Community Resources
- [Prometheus Community](https://prometheus.io/community/)
- [Grafana Community](https://community.grafana.com/)

---

## 📞 Support & Troubleshooting

**Issue Reporting:**
1. Check logs: `docker-compose logs -f`
2. Verify targets: http://localhost:9090/targets
3. Check alert status: http://localhost:9093
4. Review configurations for syntax errors

**Getting Help:**
- Prometheus Docs: https://prometheus.io/docs/
- Stack Overflow: [tag:prometheus]
- Telegram Bot Issues: Contact [@BotFather](https://t.me/botfather)

---

**Last Updated**: July 2, 2026  
**Repository**: https://github.com/nahid-devops2021/prometheus-grafana  
**License**: MIT

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-02 | Initial comprehensive documentation |

