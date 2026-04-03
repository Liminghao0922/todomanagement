# Todo Management 部署指南

[English](DEPLOY_GUIDE.md) | [简体中文](DEPLOY_GUIDE-zh_CN.md) | [日本語](DEPLOY_GUIDE-ja_JP.md)

本文档说明本仓库的默认部署流程。

预计耗时：30 到 40 分钟。

## 前置条件
- Azure 订阅（`Contributor` 或 `Owner` 权限）
- 已启用 GitHub Actions 的仓库
- Azure Cloud Shell（PowerShell）或本地 Azure CLI
- 如果需要提交工作流文件，需在本地安装 Git

## 1. 创建或克隆仓库
如果你是从模板仓库开始，请先在 GitHub 中基于模板创建新仓库，再在本地或 Cloud Shell 中克隆。

## 2. 选择订阅并打开 Cloud Shell
部署前先确认目标订阅。

```powershell
az account show
az account set --subscription "<subscription-id>"
```

## 3. 克隆仓库
```powershell
git clone <your-repo-url>
cd todomanagement
```

## 4. 检查基础设施参数
打开 `infra/parameters.json`，至少确认以下参数：
- `location`
- `environment`
- `projectName`
- `postgresqlAdminPassword`

## 5. 部署基础设施
```powershell
cd infra
$resourceGroupName = "rg-todomanagement-dev"
$location = "japaneast"
.\deploy.ps1 -ResourceGroupName $resourceGroupName -Location $location
```

请记录部署输出（PostgreSQL 主机与数据库、ACR 名称、API URL、WEB URL、UAI 标识）。

## 6. 为 GitHub Actions 准备 Azure 凭据
准备 `azure/login` 使用的 JSON 凭据，并在 GitHub 中保存为 `AZURE_CREDENTIALS`。

## 7. 配置 GitHub Secrets 和 Variables
必需 Secret：
- `AZURE_CREDENTIALS`

常用 Variables：
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

这些值可从部署输出、Azure Portal 或 Azure CLI 中获取。

## 8. 初始化工作流
从模板创建工作流文件：
- `.github/workflows/build-deploy-api.yml.template` -> `.github/workflows/build-deploy-api.yml`
- `.github/workflows/build-deploy-web.yml.template` -> `.github/workflows/build-deploy-web.yml`

## 9. 提交并触发部署
- 提交工作流文件以及必要的参数修改
- 推送到 `main` 分支，或
- 在 GitHub 上手动触发 `workflow_dispatch`

## 10. 验证
- API 健康检查：`https://<api-fqdn>/health`
- Web 地址：`https://<web-fqdn>/`
- 确认 Entra 应用回调地址包含部署后的 Web URL
- 确认登录成功，并且 Todo 数据可以正常加载

## 相关文档
- `README-zh_CN.md`
- `docs/ARCHITECTURE_GUIDE-zh_CN.md`
- `infra/README.md`
- `.github/workflows/build-deploy-api.yml.template`
- `.github/workflows/build-deploy-web.yml.template`
