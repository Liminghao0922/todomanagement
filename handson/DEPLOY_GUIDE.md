# Todo Management Deployment Guide

[English](DEPLOY_GUIDE.md) | [简体中文](DEPLOY_GUIDE-zh_CN.md) | [日本語](DEPLOY_GUIDE-ja_JP.md)

This guide explains the default deployment flow for this repository.

Estimated time: 30 to 40 minutes.

## Prerequisites
- Azure subscription with `Contributor` or `Owner`
- GitHub repository with Actions enabled
- Azure Cloud Shell (PowerShell) or local Azure CLI
- Git installed locally if you plan to commit workflow files from your machine

## 1. Create or Clone the Repository
If you are using this project as a template, create a new repository from the template first. Then clone it locally or in Cloud Shell.

## 2. Select Subscription and Open Cloud Shell
Verify the target subscription before deployment.

```powershell
az account show
az account set --subscription "<subscription-id>"
```

## 3. Clone Repository
```powershell
git clone <your-repo-url>
cd todomanagement
```

## 4. Review Infrastructure Parameters
Open `infra/parameters.json` and confirm at least:
- `location`
- `environment`
- `projectName`
- `postgresqlAdminPassword`

## 5. Deploy Infrastructure
```powershell
cd infra
$resourceGroupName = "rg-todomanagement-dev"
$location = "japaneast"
.\deploy.ps1 -ResourceGroupName $resourceGroupName -Location $location
```

Record deployment outputs (PostgreSQL host/db, ACR name, API URL, WEB URL, UAI IDs).

## 6. Create Azure Credentials for GitHub Actions
Prepare the JSON secret used by `azure/login`, then store it in GitHub as `AZURE_CREDENTIALS`.

## 7. Configure GitHub Secrets and Variables
Required secret:
- `AZURE_CREDENTIALS`

Common variables:
- `ACR_NAME`
- `RESOURCE_GROUP`
- `CONTAINER_APP_ENVIRONMENT`
- `DATABASE_TYPE`
- `POSTGRES_SERVER`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_REDIRECT_URI`
- `API_PROXY_TARGET`
- `USER_ASSIGNED_IDENTITY_CLIENT_ID`
- `USER_ASSIGNED_IDENTITY_RESOURCE_ID`

Capture these values from deployment outputs, Azure Portal, or Azure CLI.

## 8. Initialize Workflows
Create workflow files from templates:
- `.github/workflows/build-deploy-api.yml.template` -> `.github/workflows/build-deploy-api.yml`
- `.github/workflows/build-deploy-web.yml.template` -> `.github/workflows/build-deploy-web.yml`

## 9. Commit and Trigger Deployment
- Commit the workflow files and any parameter changes
- Push to `main`, or
- Run `workflow_dispatch` for both workflows

## 10. Validate
- API health: `https://<api-fqdn>/health`
- Web app: `https://<web-fqdn>/`
- Verify Entra redirect URI includes deployed web URL
- Verify sign-in succeeds and Todo data loads correctly

## Related Docs
- `README.md`
- `docs/ARCHITECTURE_GUIDE.md`
- `infra/README.md`
- `.github/workflows/build-deploy-api.yml.template`
- `.github/workflows/build-deploy-web.yml.template`
