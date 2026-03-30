# Azure Infrastructure Deployment Script for {{PROJECT_TITLE}} (PowerShell)
# This script deploys all infrastructure including VNet, PostgreSQL, Container Registry, and Container App Environment
# 
# Usage: .\deploy.ps1 -ResourceGroupName "rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}" -Location "{{AZURE_REGION}}"

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "{{AZURE_REGION}}",
    
    [Parameter(Mandatory = $false)]
    [string]$Environment = "{{ENVIRONMENT}}"
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
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Infrastructure Details" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "PostgreSQL Server: $($outputs.postgresqlServerName.value)"
Write-Host "PostgreSQL Hostname: $($outputs.postgresqlHostname.value)"
Write-Host "Container Registry Login Server: $($outputs.containerRegistryLoginServer.value)"
Write-Host "Container App Environment: $($outputs.containerAppEnvironmentName.value)"
Write-Host "Database Name: $($outputs.databaseName.value)"
Write-Host ""
Write-Host "Subnet IDs:" -ForegroundColor Cyan
Write-Host "  PostgreSQL Subnet: $($outputs.postgresSubnetId.value)"
Write-Host "  Container App Subnet: $($outputs.containerAppSubnetId.value)"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure PostgreSQL Entra ID authentication"
Write-Host "  2. Deploy Container Apps"
Write-Host "  3. Create PostgreSQL managed identity roles"
Write-Host ""

# Save outputs to file for future reference
Write-Host "[4/4] Saving deployment outputs..." -ForegroundColor Yellow
$outputObject = @{
    resourceGroupName = $ResourceGroupName
    location = $Location
    environment = $Environment
    postgresqlServerName = $outputs.postgresqlServerName.value
    postgresqlHostname = $outputs.postgresqlHostname.value
    postgresqlServerId = $outputs.postgresqlServerId.value
    databaseName = $outputs.databaseName.value
    containerAppEnvironmentName = $outputs.containerAppEnvironmentName.value
    containerAppEnvironmentId = $outputs.containerAppEnvironmentId.value
    containerRegistryName = $outputs.containerRegistryName.value
    containerRegistryLoginServer = $outputs.containerRegistryLoginServer.value
    vnetId = $outputs.vnetId.value
    postgresSubnetId = $outputs.postgresSubnetId.value
    containerAppSubnetId = $outputs.containerAppSubnetId.value
}

$outputJson = $outputObject | ConvertTo-Json
$outputJson | Out-File -FilePath "deployment-outputs.json" -Encoding UTF8
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Deployment Completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Deployment outputs saved to: deployment-outputs.json" -ForegroundColor Green
