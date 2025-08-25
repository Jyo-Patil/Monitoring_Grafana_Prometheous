#!/bin/bash

# Monitoring Stack Deployment Script
# This script deploys Prometheus, Grafana, and CloudWatch monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="zomato-cluster"
REGION="us-east-1"
NAMESPACE_MONITORING="monitoring"
NAMESPACE_CLOUDWATCH="amazon-cloudwatch"

echo -e "${GREEN}🚀 Starting Monitoring Stack Deployment...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

if ! command_exists helm; then
    echo -e "${RED}❌ helm is not installed${NC}"
    exit 1
fi

if ! command_exists aws; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Update kubeconfig
echo -e "${YELLOW}🔧 Updating kubeconfig for EKS cluster...${NC}"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Add Helm repositories
echo -e "${YELLOW}📚 Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add amazon-cloudwatch https://aws.github.io/amazon-cloudwatch-agent
helm repo update

# Create namespaces
echo -e "${YELLOW}🏗️  Creating namespaces...${NC}"
kubectl create namespace $NAMESPACE_MONITORING --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_CLOUDWATCH --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus Stack
echo -e "${YELLOW}📊 Deploying Prometheus Stack...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace $NAMESPACE_MONITORING \
    --create-namespace \
    --values ../helm-values/prometheus-values.yaml \
    --wait \
    --timeout 10m

# Deploy CloudWatch Agent
echo -e "${YELLOW}☁️  Deploying CloudWatch Agent...${NC}"
helm upgrade --install cloudwatch-agent amazon-cloudwatch/amazon-cloudwatch-agent \
    --namespace $NAMESPACE_CLOUDWATCH \
    --create-namespace \
    --values ../helm-values/cloudwatch-values.yaml \
    --wait \
    --timeout 5m

# Apply alerting rules
echo -e "${YELLOW}🚨 Applying alerting rules...${NC}"
kubectl apply -f ../alerts/application-alerts.yaml -n $NAMESPACE_MONITORING

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n $NAMESPACE_MONITORING --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $NAMESPACE_MONITORING --timeout=300s

# Get service URLs
echo -e "${YELLOW}🔍 Getting service URLs...${NC}"
GRAFANA_SERVICE=$(kubectl get svc -n $NAMESPACE_MONITORING -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_SERVICE=$(kubectl get svc -n $NAMESPACE_MONITORING -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')

# Port forward services (optional)
echo -e "${GREEN}🎉 Monitoring stack deployed successfully!${NC}"
echo -e "${YELLOW}📋 Service Information:${NC}"
echo -e "  Grafana: kubectl port-forward -n $NAMESPACE_MONITORING svc/$GRAFANA_SERVICE 3000:80"
echo -e "  Prometheus: kubectl port-forward -n $NAMESPACE_MONITORING svc/$PROMETHEUS_SERVICE 9090:9090"
echo -e ""
echo -e "${GREEN}🔑 Default Credentials:${NC}"
echo -e "  Grafana: admin/admin123"
echo -e ""
echo -e "${YELLOW}📊 To access services:${NC}"
echo -e "  1. Run the port-forward commands above"
echo -e "  2. Open Grafana: http://localhost:3000"
echo -e "  3. Open Prometheus: http://localhost:9090"
echo -e ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
