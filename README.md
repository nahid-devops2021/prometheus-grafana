# Prometheus & Grafana Monitoring Setup

A comprehensive monitoring solution combining **Prometheus** for metrics collection, **Alertmanager** for alert management, and **Grafana** for visualization and dashboards. This repository provides a complete DevOps monitoring stack with Docker Compose for easy deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Alertmanager Setup](#alertmanager-setup)
- [Usage](#usage)
- [Accessing Dashboards](#accessing-dashboards)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository provides a production-ready monitoring stack that enables DevOps and Operations Engineers to:
- Collect and store metrics from various sources using **Prometheus**
- Manage and route alerts efficiently using **Alertmanager**
- Visualize metrics and create custom dashboards using **Grafana**
- Monitor infrastructure, applications, and services in real-time
- Set up alerts and notifications for critical events
- Route alerts to multiple channels (email, Slack, PagerDuty, etc.)

## ✨ Features

- **Prometheus**: Time-series database for metrics collection and storage
- **Alertmanager**: Alert routing, grouping, and notification management
- **Grafana**: Powerful visualization and dashboard creation platform
- **Docker Compose**: One-command deployment of the entire monitoring stack
- **Pre-configured Dashboards**: Ready-to-use Grafana dashboards for common use cases
- **Alert Rules**: Pre-configured alert rules for common scenarios
- **Exporters Configuration**: Support for various Prometheus exporters (Node Exporter, cAdvisor, etc.)
- **Persistent Storage**: Docker volumes for data persistence
- **Multi-channel Notifications**: Email, Slack, PagerDuty, Webhook support
- **Scalable Architecture**: Easy to extend and customize for your infrastructure

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
  - Installation: https://docs.docker.com/install/
- **Docker Compose** (version 1.29 or higher)
  - Installation: https://docs.docker.com/compose/install/
- **Git** (for cloning the repository)
- **Minimum Resources**: 
  - 2 CPU cores
  - 2 GB RAM
  - 10 GB disk space (for data storage)

**Verify Installation:**
```bash
docker --version
docker-compose --version
```

## 📁 Directory Structure

```
prometheus-grafana/
├── docker-compose.yml              # Main Docker Compose configuration
├── prometheus/
│   ├── prometheus.yml              # Prometheus configuration file
│   ├── alert.rules.yml             # Alert rules configuration
│   └── data/                       # Prometheus time-series data (volume)
├── alertmanager/
│   ├── alertmanager.yml            # Alertmanager configuration
│   └── data/                       # Alertmanager data (volume)
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/            # Data source configurations
│   │   └── dashboards/             # Pre-configured dashboards
│   ├── grafana.ini                 # Grafana configuration
│   └── data/                       # Grafana data (volume)
├── config/                         # Additional configuration files
│   └── docker.yml                  # Docker daemon monitoring config
├── Dockerfile                      # Custom container images (if any)
└── README.md                       # This file
```

## 🚀 Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/nahid-devops2021/prometheus-grafana.git
cd prometheus-grafana
```

### Step 2: Create Required Directories

```bash
mkdir -p prometheus/data
mkdir -p alertmanager/data
mkdir -p grafana/data
chmod 777 prometheus/data alertmanager/data grafana/data
```

### Step 3: Start the Services

```bash
docker-compose up -d
```

This command will:
- Pull the necessary Docker images
- Create and start Prometheus, Alertmanager, and Grafana containers
- Create persistent volumes for data storage
- Set up the network for inter-container communication

### Step 4: Verify Services

```bash
docker-compose ps
```

You should see `prometheus`, `alertmanager`, and `grafana` containers in "Up" state.

## ⚙️ Configuration

### Prometheus Configuration

The `prometheus/prometheus.yml` file controls:
- **Global settings**: Scrape intervals and evaluation intervals
- **Scrape targets**: Where to collect metrics from
- **Alert rules**: Rules for triggering alerts
- **Alertmanager**: Integration with Alertmanager

**Example Prometheus Configuration:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'prometheus'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load alert rules
rule_files:
  - "alert.rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
  
  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
```

To add a new target:
1. Edit `prometheus/prometheus.yml`
2. Add a new `scrape_configs` section
3. Restart Prometheus: `docker-compose restart prometheus`

### Alert Rules Configuration

The `prometheus/alert.rules.yml` file defines alert conditions:

**Example Alert Rules:**
```yaml
groups:
  - name: example_alerts
    interval: 30s
    rules:
      - alert: HighMemoryUsage
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is below 20% available (current value: {{ $value | humanizePercentage }})"

      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been unreachable for more than 1 minute"
```

## 🚨 Alertmanager Setup

### Alertmanager Configuration

The `alertmanager/alertmanager.yml` file configures:
- **Routes**: How to route alerts to different receivers
- **Receivers**: Notification channels (email, Slack, etc.)
- **Grouping**: How to group related alerts
- **Inhibition**: Rules to suppress certain alerts

**Complete Alertmanager Configuration Example:**
```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
  smtp_from: 'alerts@example.com'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  
  routes:
    # Critical alerts to PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty'
      group_wait: 10s
    
    # High priority alerts to Slack
    - match:
        severity: high
      receiver: 'slack'
    
    # Low priority to email
    - match:
        severity: low
      receiver: 'email'
      group_interval: 12h

receivers:
  # Default receiver
  - name: 'default'
    slack_configs:
      - channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  # Slack notifications
  - name: 'slack'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#critical-alerts'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true

  # Email notifications
  - name: 'email'
    email_configs:
      - to: 'ops-team@example.com'
        from: 'alerts@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
        headers:
          Subject: '{{ .GroupLabels.alertname }} - {{ .Status | toUpper }}'

  # PagerDuty notifications
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}: {{ .Status | toUpper }}'

# Inhibition rules (suppress alerts under certain conditions)
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
  
  - source_match_re:
      severity: ^(warning|info)$
    target_match:
      severity: 'info'
```

### Setting Up Notifications

#### Slack Integration
1. Create a Slack workspace and channel for alerts
2. Create an Incoming Webhook: https://api.slack.com/messaging/webhooks
3. Copy the webhook URL and add to `alertmanager.yml`

#### Email Integration (Gmail Example)
1. Enable 2-Factor Authentication on Gmail
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the app password in `alertmanager.yml`

#### PagerDuty Integration
1. Create PagerDuty account and service
2. Get the integration key from service settings
3. Add to `alertmanager.yml`

### Grafana Configuration

The `grafana/provisioning/datasources/` directory contains data source definitions. Modify `prometheus.yml` to connect to your Prometheus instance:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

### Custom Dashboards

Place JSON dashboard files in `grafana/provisioning/dashboards/`:
1. Export dashboards from Grafana (Dashboard menu > Export)
2. Save JSON files to the provisioning directory
3. Restart Grafana to automatically load them

## 📊 Usage

### Starting Services
```bash
docker-compose up -d
```

### Stopping Services
```bash
docker-compose down
```

### Viewing Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f prometheus
docker-compose logs -f alertmanager
docker-compose logs -f grafana
```

### Restarting Services
```bash
docker-compose restart

# Restart specific service
docker-compose restart prometheus
docker-compose restart alertmanager
```

### Validating Alertmanager Configuration
```bash
docker-compose exec alertmanager amtool config routes
docker-compose exec alertmanager amtool check-config
```

### Testing Alerts
```bash
# Check if alerts are being triggered
docker-compose exec prometheus promtool query instant 'ALERTS'

# Test Alertmanager configuration
docker-compose restart alertmanager
docker-compose logs alertmanager
```

## 🔗 Accessing Dashboards

### Prometheus UI
- **URL**: http://localhost:9090
- **Default Port**: 9090
- **Features**: 
  - Query metrics
  - View targets and their health
  - Monitor alerts status
  - Execute PromQL queries

### Alertmanager UI
- **URL**: http://localhost:9093
- **Default Port**: 9093
- **Features**:
  - View active alerts
  - View silenced alerts
  - Create alert silences
  - Inspect alert groups
  - View notification status

### Grafana
- **URL**: http://localhost:3000
- **Default Port**: 3000
- **Default Credentials**:
  - Username: `admin`
  - Password: `admin` (change on first login)

**First Time Setup:**
1. Login with default credentials
2. Change the admin password immediately
3. Add Prometheus as a data source (http://prometheus:9090)
4. Import or create dashboards
5. Configure alert notifications in Grafana (optional, Alertmanager is preferred)

## 🛠️ Troubleshooting

### Issue: Containers won't start
```bash
# Check logs
docker-compose logs

# Verify port availability
netstat -an | grep 9090
netstat -an | grep 9093
netstat -an | grep 3000

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Issue: Alertmanager not receiving alerts
1. Verify Prometheus configuration includes alertmanager targets
2. Check Alertmanager logs: `docker-compose logs alertmanager`
3. Verify alertmanager.yml syntax: `docker-compose exec alertmanager amtool check-config`
4. Check if alerts are being triggered: http://localhost:9090/alerts
5. Restart services: `docker-compose restart`

### Issue: Alerts not routing correctly
1. Verify routes in alertmanager.yml are configured correctly
2. Check alert labels match route matchers
3. Test with: `docker-compose exec alertmanager amtool config routes`
4. Check receiver configuration and webhook URLs

### Issue: No data appearing in Grafana
1. Verify Prometheus targets are healthy: http://localhost:9090/targets
2. Check data source configuration in Grafana
3. Ensure firewall allows connections between containers
4. Restart services: `docker-compose restart`

### Issue: Permission denied errors
```bash
# Fix data directory permissions
sudo chown -R $(id -u):$(id -g) prometheus/data alertmanager/data grafana/data
chmod -R 755 prometheus/data alertmanager/data grafana/data
```

### Issue: High Memory/CPU Usage
1. Reduce scrape frequency in `prometheus.yml` (increase scrape_interval)
2. Reduce retention period for Prometheus: Add `--storage.tsdb.retention.time=30d`
3. Check for excessive logging in `docker-compose logs`
4. Limit number of alerts per rule

## 📝 Common Commands

```bash
# View running containers
docker-compose ps

# View logs from all services
docker-compose logs -f --tail=100

# Execute command in container
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Check Alertmanager status
docker-compose exec alertmanager amtool status

# Remove all data and start fresh
docker-compose down -v

# View resource usage
docker stats

# Test alert routing
docker-compose exec alertmanager amtool config routes
```

## 🔐 Security Considerations

- Change default Grafana credentials immediately
- Use reverse proxy (nginx, traefik) for production
- Implement authentication and SSL/TLS
- Restrict access to Prometheus UI (no authentication by default)
- Restrict access to Alertmanager UI
- Use `.env` file for sensitive configuration (don't commit to git)
- Keep Docker images updated
- Encrypt webhook URLs and API keys in configuration
- Use environment variables for sensitive data:

```bash
# .env file example
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
PAGERDUTY_KEY=your-key-here
SMTP_PASSWORD=your-password-here
```

## 📈 Monitoring Best Practices

1. **Retention Policy**: Configure appropriate retention periods
2. **Scrape Intervals**: Balance between accuracy and storage
3. **Alert Rules**: Define meaningful alerts for your infrastructure
4. **Dashboard Organization**: Group related metrics logically
5. **Documentation**: Document custom metrics and dashboards
6. **Alert Tuning**: Reduce false positives with proper thresholds
7. **Grouping Strategy**: Use `group_by` to reduce alert noise
8. **Silence Management**: Use Alertmanager silences for maintenance windows

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Alert Rules Examples](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/your-feature`)
5. Submit a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated**: July 2, 2026

For issues, questions, or suggestions, please open an issue on GitHub.
