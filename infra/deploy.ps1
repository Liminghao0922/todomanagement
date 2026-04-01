# Azure Infrastructure Deployment Script for Todo Management App (PowerShell)
# This script deploys all infrastructure including VNet, PostgreSQL, Container Registry, and Container App Environment

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-todomanagement-dev",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "japaneast",
    
    [Parameter(Mandatory = $false)]
    [string]$Environment = "dev"
)

# Set error action
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Azure Infrastructure Deployment" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check if user is logged in
Write-Host "[0/4] Checking Azure authentication..." -ForegroundColor Yellow
$currentUser = az account show 2>$null
if (-not $currentUser) {
    Write-Host ""
    Write-Host "Not logged in. Please run: az login" -ForegroundColor Red
    Write-Host ""
    Write-Host "To log in, use:" -ForegroundColor Yellow
    Write-Host "  az login" -ForegroundColor Cyan
    exit 1
}

# Get and display current subscription
$subscription = $currentUser | ConvertFrom-Json
Write-Host "Logged in as: $($subscription.user.name)" -ForegroundColor Green
Write-Host ""
Write-Host "Current subscription:" -ForegroundColor Cyan
Write-Host "  Name: $($subscription.name)" -ForegroundColor Cyan
Write-Host "  ID:   $($subscription.id)" -ForegroundColor Cyan
Write-Host ""

# Ask user to confirm subscription
$confirmSub = Read-Host "Confirm using this subscription? (y/n, default y)"
if ($confirmSub -eq "n") {
    Write-Host ""
    Write-Host "To switch subscriptions:" -ForegroundColor Yellow
    Write-Host "  1. List all subscriptions: az account list --output table" -ForegroundColor Cyan
    Write-Host "  2. Select subscription: az account set --subscription <subscription-id>"  -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Deployment Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "  Location:       $Location" -ForegroundColor Cyan
Write-Host "  Environment:    $Environment" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create Resource Group
Write-Host "[1/4] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location
Write-Host "Resource Group created: $ResourceGroupName" -ForegroundColor Green
Write-Host ""

# Step 2: Deploy main infrastructure
Write-Host "[2/4] Deploying infrastructure..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deploymentName = "infra-deployment-$timestamp"

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file "main.bicep" `
    --parameters parameters.json

Write-Host "Infrastructure deployed" -ForegroundColor Green
Write-Host ""

# Step 3: Retrieve deployment outputs
Write-Host "[3/4] Retrieving deployment outputs..." -ForegroundColor Yellow

$deployments = az deployment group list `
    --resource-group $ResourceGroupName `
    --query "[0]" | ConvertFrom-Json

$outputs = $deployments.properties.outputs

Write-Host "Deployment successful!" -ForegroundColor Green
Write-Host ""
# Step 4: Configure PostgreSQL Entra Admin (UAI)
# Bicep cannot use runtime principalId as resource name, so we use CLI here
Write-Host "[4/4] Configuring PostgreSQL Entra ID admin (User Assigned Identity)..." -ForegroundColor Yellow

$pgServerName   = $outputs.postgresqlServerName.value
$uaiPrincipalId = $outputs.userAssignedIdentityPrincipalId.value
$uaiClientId    = $outputs.userAssignedIdentityClientId.value
$uaiName        = "uai-todomanagement-$Environment"

Write-Host "  PostgreSQL Server : $pgServerName" -ForegroundColor Cyan
Write-Host "  UAI Name         : $uaiName" -ForegroundColor Cyan
Write-Host "  UAI Principal ID : $uaiPrincipalId" -ForegroundColor Cyan

az postgres flexible-server ad-admin create `
    --resource-group $ResourceGroupName `
    --server-name $pgServerName `
    --display-name $uaiName `
    --object-id $uaiPrincipalId `
    --type ServicePrincipal

if ($LASTEXITCODE -eq 0) {
    Write-Host "PostgreSQL Entra admin configured successfully" -ForegroundColor Green
} else {
    Write-Host "Warning: PostgreSQL Entra admin setup failed. Run manually if needed:" -ForegroundColor Yellow
    Write-Host "  az postgres flexible-server ad-admin create --resource-group $ResourceGroupName --server-name $pgServerName --display-name $uaiName --object-id $uaiPrincipalId --type ServicePrincipal" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Infrastructure Details" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "PostgreSQL Server: $($outputs.postgresqlServerName.value)"
Write-Host "PostgreSQL Hostname: $($outputs.postgresqlHostname.value)"
Write-Host "Container Registry Login Server: $($outputs.containerRegistryLoginServer.value)"
Write-Host "Container App Environment: $($outputs.containerAppEnvironmentName.value)"
Write-Host "Database Name: $($outputs.databaseName.value)"
Write-Host "UAI Client ID: $uaiClientId"
Write-Host ""
Write-Host "Subnet IDs:" -ForegroundColor Cyan
Write-Host "  PostgreSQL Subnet: $($outputs.postgresSubnetId.value)"
Write-Host "  Container App Subnet: $($outputs.containerAppSubnetId.value)"
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Deployment Completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
