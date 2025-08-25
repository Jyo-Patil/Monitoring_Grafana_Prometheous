# Monitoring Stack Setup

This directory contains the complete monitoring stack configuration for the Zomato Clone application.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **CloudWatch Agent**: AWS CloudWatch integration
- **AlertManager**: Alerting and notifications
- **Custom Dashboards**: Application-specific monitoring

## Structure

```
monitoring/
├── helm-values/           # Helm values for monitoring components
├── dashboards/           # Grafana dashboard JSON files
├── alerts/              # Prometheus alerting rules
├── grafana-provisioning/ # Grafana provisioning configs
└── scripts/             # Deployment and maintenance scripts
```

## Quick Start

1. Deploy monitoring stack: `./scripts/deploy-monitoring.sh`
2. Access Grafana: `http://localhost:3000` (admin/admin123)
3. Access Prometheus: `http://localhost:9090`

## Configuration

- Update `helm-values/` files for your environment
- Customize dashboards in `dashboards/` folder
- Modify alerts in `alerts/` folder
