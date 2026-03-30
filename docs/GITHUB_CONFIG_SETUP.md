# GitHub Secrets & Variables 配置指南

## 概述

本文档列出所有需要在GitHub Repository中配置的Secrets和Variables，用于CI/CD workflow正常运行。

> 💡 **提示**：如果您是从 Template 创建的项目，请先完成 [TEMPLATE_SETUP.md](../TEMPLATE_SETUP.md) 中的占位符替换。

---

## 📋 GitHub Variables (不敏感信息)

Repository Variables位置：**Settings** → **Secrets and variables** → **Variables**

| Variable Name | Value | Description |
|---|---|---|
| `ACR_NAME` | `acr{{PROJECT_NAME}}xxxxx` | Azure Container Registry的短名称（部署后从输出获取） |
| `RESOURCE_GROUP` | `rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}` | 部署目标的Azure资源组 |
| `POSTGRES_SERVER` | `postgres-{{PROJECT_NAME}}-xxxxx.postgres.database.azure.com` | PostgreSQL 服务器完整域名 |
| `POSTGRES_DB` | `tododb` | PostgreSQL 数据库名称 |
| `POSTGRES_USER` | (Entra ID user/app) | 授予 PostgreSQL 权限的 Entra ID 身份 |
| `AZURE_CLIENT_ID` | (Azure Entra ID应用ID) | Web应用的Azure Entra ID应用客户端ID |
| `AZURE_TENANT_ID` | (你的Azure租户ID) | Azure租户ID |
| `AZURE_REDIRECT_URI` | `https://{{PROJECT_NAME}}-web-xxxxx.{{AZURE_REGION}}.azurecontainerapps.io` | OAuth重定向URI（部署后的web应用URL） |
| `API_BASE_URL` | `https://{{PROJECT_NAME}}-api-xxxxx.{{AZURE_REGION}}.azurecontainerapps.io` | API服务的基础URL |
| `USER_ASSIGNED_IDENTITY_CLIENT_ID` | (托管身份 Client ID) | Container App使用的用户分配托管标识ID |

### 设置步骤

1. 进入GitHub repo
2. 点击 **Settings** tab
3. 左侧菜单选择 **Secrets and variables** → **Variables**
4. 点击 **New repository variable**
5. 依次添加上表中的变量

---

## 🔐 GitHub Secrets (敏感信息)

Repository Secrets位置：**Settings** → **Secrets and variables** → **Secrets**

| Secret Name | Value | Description |
|---|---|---|
| `AZURE_CREDENTIALS` | JSON对象 | Azure Service Principal凭证（JSON格式） |

### 创建 AZURE_CREDENTIALS

#### 方法1：使用Azure CLI (推荐)

在本地运行以下命令（需要有Azure CLI和Contributor权限）：

```powershell
# 替换 <SUBSCRIPTION_ID> 和 <RESOURCE_GROUP> 为实际值
$subscriptionId = "your-subscription-id-here"
$resourceGroup = "rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}"

az ad sp create-for-rbac `
  --name "github-todomanagement-actions" `
  --role "Contributor" `
  --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
  --json-auth
```

#### 方法2：使用Azure Portal

1. 前往 Azure AD → App registrations → New registration
2. 设置名称为 `github-todomanagement-actions`
3. 创建credentials：Certificates & secrets → New client secret
4. 记录：
   - Application (client) ID
   - Client secret value
   - Tenant ID
5. 分配RBAC角色：Resource group → Access control (IAM) → Add role assignment
   - Role: Contributor
   - Assign to: 上面创建的Service Principal

### 设置 AZURE_CREDENTIALS Secret

1. 复制上面命令的JSON输出
2. 进入GitHub repo
3. **Settings** → **Secrets and variables** → **Secrets**
4. 点击 **New repository secret**
5. Name: `AZURE_CREDENTIALS`
6. Value: 粘贴完整的JSON内容
7. 点击 **Add secret**

**JSON示例格式：**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-secret-value",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.microsoft.com/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

---

## ✅ 验证配置

### 1. 检查Variables是否正确

```bash
# GitHub CLI (装有gh的情况下)
gh repo variable list
```

Expected output:
```
ACR_NAME  acrtodomanagementvkql5e2kbh2na
RESOURCE_GROUP  rg-todomanagement-dev
```

### 2. 检查Secrets是否已设置

```bash
gh repo secret list
```

Expected output:
```
AZURE_CREDENTIALS  ***
```

### 3. 测试Workflow执行

1. 修改并push代码到 `src/api/` 或 `src/web/` 目录
2. 进入 **Actions** tab
3. 查看对应的workflow (Build and Deploy API/Web)
4. 等待执行完成

Success标志：
- ✅ Build and deploy Container App步骤成功
- ✅ Container image在ACR中创建
- ✅ Container App获得新的Revision

---

## 🔄 更新配置

### 更新Variables

1. **Settings** → **Secrets and variables** → **Variables**
2. 点击要编辑的变量
3. 修改Value
4. 点击 **Update variable**

### 轮换 AZURE_CREDENTIALS Secret

1. 在Azure中为Service Principal创建新的Client Secret
2. 生成新的JSON (步骤同上)
3. **Settings** → **Secrets and variables** → **Secrets**
4. 点击 `AZURE_CREDENTIALS`
5. 点击 **Update secret**
6. 粘贴新JSON
7. 删除旧的Client Secret (在Azure AD中)

---

## 🚨 安全最佳实践

✅ **必做**
- 定期轮换 `AZURE_CREDENTIALS` 中的 client secret (建议每90天)
- 最小权限原则：Service Principal仅授予 **Contributor** 权限到特定资源组
- 不要将secrets提交到Git

❌ **禁止**
- 把secrets硬编码在workflow文件中
- 在GitHub issues或discussions中讨论敏感值
- 通过不安全的渠道分享凭证

---

## 📝 变更日志

| 日期 | 变更 | 说明 |
|---|---|---|
| 2026-03-25 | 初始化 | 创建CI/CD配置指南 |

---

## 💡 故障排除

### Workflow失败：Login失败

**症状：** `azure/login` 步骤失败

**解决方案：**
- 检查 `AZURE_CREDENTIALS` Secret是否正确设置
- 验证JSON格式是否有效
- 确保Service Principal有对应资源组的Contributor权限

### Workflow失败：Container App找不到

**症状：** Build成功但deploy失败，提示Container App不存在

**解决方案：**
- 验证 `RESOURCE_GROUP` Variable正确
- 确认Container App名称正确 (`todomanagement-api` / `todomanagement-web`)
- 检查Container App是否在正确的资源组中

### ACR Build失败

**症状：** Build and deploy步骤失败

**解决方案：**
- 检查 `ACR_NAME` Variable是否正确
- 确保ACR网络配置允许来自GitHub Actions的访问
- 如果使用Private Endpoint，确保从正确的VNet/IP range访问

---

## 📚 相关文档

- [部署检查清单](./DEPLOYMENT_CHECKLIST.md)
- [架构指南](./ARCHITECTURE_GUIDE.md)
- [Azure官方文档 - GitHub Actions + Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/github-actions)
- [GitHub数据安全](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
