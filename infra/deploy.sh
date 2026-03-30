#！/bin/bash

# Azure Infrastructure Deployment Script for Todo Management App
# This script deploys all infrastructure including VNet, PostgreSQL, Container Registry, and Container App Environment

set -e

# Configuration variables
RESOURCE_GROUP_NAME="rg-todomanagement-dev"
LOCATION="japaneast"
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)

echo "==========================================="
echo "Azure Infrastructure Deployment"
echo "==========================================="
echo "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Location: $LOCATION"
echo ""

# Create Resource Group
echo "[1/3] Creating Resource Group..."
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo "✓ Resource Group created: $RESOURCE_GROUP_NAME"
echo ""

# Deploy main infrastructure (VNet, PostgreSQL, Container Registry, Container App Environment)
echo "[2/3] Deploying main infrastructure (VNet, PostgreSQL, ACR, Container App Environment)..."
az deployment group create \
  --name "infra-deployment-$(date +%s)" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --template-file "main.bicep" \
  --parameters parameters.json

echo "✓ Infrastructure deployed successfully"
echo ""

# Get outputs from the deployment
echo "[3/3] Retrieving deployment outputs..."
DEPLOYMENT_OUTPUTS=$(az deployment group list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query "[0].properties.outputs" -o json)

POSTGRES_SERVER_NAME=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.postgresqlServerName.value')
POSTGRES_HOSTNAME=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.postgresqlHostname.value')
ACR_LOGIN_SERVER=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.containerRegistryLoginServer.value')
CONTAINER_APP_ENV_ID=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.containerAppEnvironmentId.value')
CONTAINER_APP_ENV_NAME=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.containerAppEnvironmentName.value')
POSTGRES_SUBNET_ID=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.postgresSubnetId.value')
CONTAINER_APP_SUBNET_ID=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.containerAppSubnetId.value')

echo "✓ Deployment completed successfully!"
echo ""
echo "==========================================="
echo "Infrastructure Details"
echo "==========================================="
echo "PostgreSQL Server: $POSTGRES_SERVER_NAME"
echo "PostgreSQL Hostname: $POSTGRES_HOSTNAME"
echo "Container Registry Login Server: $ACR_LOGIN_SERVER"
echo "Container App Environment: $CONTAINER_APP_ENV_NAME"
echo "Container App Environment ID: $CONTAINER_APP_ENV_ID"
echo ""
echo "Subnets:"
echo "  PostgreSQL Subnet ID: $POSTGRES_SUBNET_ID"
echo "  Container App Subnet ID: $CONTAINER_APP_SUBNET_ID"
echo ""
echo "Next Steps:"
echo "1. Configure PostgreSQL Entra ID authentication"
echo "2. Deploy Container Apps"
echo "3. Configure PostgreSQL firewall rules for Container Apps"
echo ""
