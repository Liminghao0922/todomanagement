# GitHub Workflow 配置指南

## 📋 GitHub Secrets 设置

在部署workflow之前，您需要在GitHub仓库中配置以下Secrets。

### 访问GitHub Secrets设置
1. 进入仓库 → **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret** 添加每个Secret

## 必需的 Secrets

### 1. Azure 认证凭证

#### `AZURE_CREDENTIALS`
用于GitHub Action在Azure中进行认证。

**获取方式：**
```bash
# 创建服务主体
az ad sp create-for-rbac \
  --name "github-actions-todomanagement" \
  --role "Contributor" \
  --scopes /subscriptions/<subscription-id> \
  --json-auth
```

**输出格式（直接复制整个JSON）：**
```json
{
  "clientId": "xxxx",
  "clientSecret": "xxxx",
  "subscriptionId": "xxxx",
  "tenantId": "xxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 2. Azure Container Registry (ACR) 凭证

#### `ACR_LOGIN_SERVER`
ACR的登录服务器地址。

**获取方式：**
```bash
az acr show \
  --name <acr-name> \
  --query loginServer \
  -o tsv
```

**示例值：** `acrtodemanagementixxxxx.azurecr.io`

#### `ACR_USERNAME`
ACR管理员用户名。

**获取方式：**
```bash
az acr credential show \
  --name <acr-name> \
  --query username \
  -o tsv
```

#### `ACR_PASSWORD`
ACR管理员密码。

⚠️ **安全提示：** 建议使用ACR令牌而非管理员密码。

**获取方式：**
```bash
# 显示第一个密码
az acr credential show \
  --name <acr-name> \
  --query "passwords[0].value" \
  -o tsv
```

### 3. Azure 资源信息 (单环境)

如果只使用 `build-deploy.yml`（单环境）：

#### `AZURE_RESOURCE_GROUP`
资源组名称。

**示例值：** `rg-todomanagement-dev`

#### `AZURE_CONTAINER_APP_NAME`
Container App 名称。

**示例值：** `ca-todomanagement-api-dev`

### 4. Azure 资源信息 (多环境)

如果使用 `build-deploy-multi-env.yml`（推荐），需要设置对应环境的变量：

#### 开发环境 (Dev)
- `AZURE_RG_DEV` - 开发资源组
- `AZURE_CONTAINER_APP_DEV` - 开发Container App

#### 预发布环境 (Staging)
- `AZURE_RG_STAGING` - 预发布资源组
- `AZURE_CONTAINER_APP_STAGING` - 预发布Container App

#### 生产环境 (Prod)
- `AZURE_RG_PROD` - 生产资源组
- `AZURE_CONTAINER_APP_PROD` - 生产Container App

**示例：**
```
AZURE_RG_DEV = rg-todomanagement-dev
AZURE_CONTAINER_APP_DEV = ca-todomanagement-api-dev

AZURE_RG_STAGING = rg-todomanagement-staging
AZURE_CONTAINER_APP_STAGING = ca-todomanagement-api-staging

AZURE_RG_PROD = rg-todomanagement-prod
AZURE_CONTAINER_APP_PROD = ca-todomanagement-api-prod
```

### 5. Slack 通知（可选）

#### `SLACK_WEBHOOK`
Slack Webhook URL（用于部署通知）。

**获取方式：**
1. 进入 [Slack Apps](https://api.slack.com/apps/)
2. 创建新应用或选择现有应用
3. 进入 **Incoming Webhooks** → **Add New Webhook to Workspace**
4. 选择通知频道
5. 复制 Webhook URL

**示例值：** `https://hooks.slack.com/services/YOUR-WEBHOOK-URL`

## 🔐 快速设置脚本

以下脚本可帮助您快速设置所有Secrets：

### PowerShell 脚本

```powershell
# Set-GitHubSecrets.ps1

$OwnerRepo = "Liminghao0922/todomanagement"
$GitHubToken = Read-Host "Enter your GitHub Personal Access Token"

# Function to set a secret
function Set-GitHubSecret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )
    
    $Body = @{
        encrypted_value = $SecretValue
        key_id = "652620424"
    } | ConvertTo-Json
    
    $Headers = @{
        Authorization = "Bearer $GitHubToken"
        Accept = "application/vnd.github+json"
    }
    
    Invoke-RestMethod -Uri "https://api.github.com/repos/$OwnerRepo/actions/secrets/$SecretName" `
        -Method PUT `
        -Headers $Headers `
        -Body $Body
}

# Get Azure values
$SubscriptionId = Read-Host "Enter Azure Subscription ID"

Write-Host "Getting Azure credentials..."
$AzureCredentials = az ad sp create-for-rbac `
    --name "github-actions-todomanagement" `
    --role "Contributor" `
    --scopes "/subscriptions/$SubscriptionId" `
    --json-auth

$ACRName = Read-Host "Enter ACR name"
$ACRLoginServer = az acr show --name $ACRName --query loginServer -o tsv
$ACRUsername = az acr credential show --name $ACRName --query username -o tsv
$ACRPassword = az acr credential show --name $ACRName --query "passwords[0].value" -o tsv

# Container App names
$RGDev = Read-Host "Enter Dev Resource Group name"
$CADev = Read-Host "Enter Dev Container App name"

Write-Host "✓ Setting GitHub Secrets..."

# 这里实际应使用正确的API调用，但GitHub CLI更简单
gh secret set AZURE_CREDENTIALS --body "$AzureCredentials"
gh secret set ACR_LOGIN_SERVER --body "$ACRLoginServer"
gh secret set ACR_USERNAME --body "$ACRUsername"
gh secret set ACR_PASSWORD --body "$ACRPassword"
gh secret set AZURE_RG_DEV --body "$RGDev"
gh secret set AZURE_CONTAINER_APP_DEV --body "$CADev"

Write-Host "✅ GitHub Secrets configured successfully!"
```

### Bash 脚本

```bash
#!/bin/bash

REPO="Liminghao0922/todomanagement"
ACR_NAME="acrtodemanagementixxxxx"
RG_DEV="rg-todomanagement-dev"
CA_DEV="ca-todomanagement-api-dev"

echo "Setting GitHub Secrets..."

# Get Azure Credentials
AZURE_CREDS=$(az ad sp create-for-rbac \
  --name "github-actions-todomanagement" \
  --role "Contributor" \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --json-auth)

gh secret set AZURE_CREDENTIALS --body "$AZURE_CREDS"

# Get ACR credentials
ACR_LOGIN=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASS=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

gh secret set ACR_LOGIN_SERVER --body "$ACR_LOGIN"
gh secret set ACR_USERNAME --body "$ACR_USER"
gh secret set ACR_PASSWORD --body "$ACR_PASS"

# Container App info
gh secret set AZURE_RG_DEV --body "$RG_DEV"
gh secret set AZURE_CONTAINER_APP_DEV --body "$CA_DEV"

echo "✅ Secrets configured successfully!"
```

## 📊 Workflow 触发条件

### `build-deploy.yml` (基础版)
- ✅ 代码推送到 `main` 或 `develop` 分支
- ✅ Pull Request 创建到 `main` 或 `develop`
- ✅ 手动触发 (workflow_dispatch)
- ✅ `src/` 目录有变更
- ✅ Workflow 文件有变更

**部署条件：**
- 仅在 `main` 分支上的 push 时部署

### `build-deploy-multi-env.yml` (多环境版)
- ✅ 代码推送到 `main`, `develop`, 或 `staging`
- ✅ Pull Request 创建
- ✅ 手动触发 + 选择环境

**部署条件：**
- `main` → `prod`
- `staging` → `staging`
- `develop` → `dev`
- 手动选择目标环境

## 🚀 使用 Workflows

### 自动构建并部署（推送代码）
```bash
# 这会自动触发workflow
git add .
git commit -m "Update API code"
git push origin main
```

### 手动部署
1. 进入仓库 → **Actions** 标签
2. 选择 workflow: "Build and Deploy (Multi-Environment)"
3. 点击 **Run workflow**
4. 选择目标环境
5. 点击 **Run workflow** 按钮

### 查看构建日志
1. 进入 **Actions** 标签
2. 点击最新的 workflow run
3. 查看各个job的详细日志

## 🆘 故障排查

### Secret 错误
```
Error: Secret not found
```
**解决：** 确保Secret名称完全匹配（大小写敏感）

### ACR 登录失败
```
Error: Invalid username or password
```
**解决：** 检查ACR_USERNAME和ACR_PASSWORD是否正确，或使用ACR令牌而非管理员密码

### Container App 更新失败
```
Error: The specified resource could not be found
```
**解决：** 确保：
- Container App 名称正确
- 资源组名称正确
- 服务主体有足够权限

### 镜像推送到ACR失败
```
Error: Unauthorized: authentication required
```
**解决：** 检查 ACR_LOGIN_SERVER, ACR_USERNAME, ACR_PASSWORD 是否正确

## ✅ 验证设置

运行以下命令验证所有配置是否正确：

```bash
# 验证服务主体
az sp show --id <servicePrincipalId>

# 验证ACR访问
az acr show --name <acrName>

# 验证Container App存在
az containerapp show --name <caName> --resource-group <rgName>

# 测试ACR登录
echo "$ACR_PASSWORD" | docker login -u "$ACR_USERNAME" --password-stdin $ACR_LOGIN_SERVER
```

## 📚 参考资源

- [GitHub Actions Azure Login](https://github.com/Azure/login)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Azure Container App 更新](https://learn.microsoft.com/zh-cn/azure/container-apps/containerapp-update-and-scale-cli)
- [GitHub Secrets 文档](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
