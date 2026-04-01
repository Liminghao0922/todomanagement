# 🔧 GitHub Actions 环境变量配置故障排查指南

## 错误症状
```
AADSTS700038: 00000000-0000-0000-0000-000000000000 is not a valid application identifier.
```

这个错误说明 `VITE_AZURE_CLIENT_ID` 或类似的 Entra ID 相关变量没有被正确设置。

---

## ✅ 解决方案

### 第1步：确认缺失的 GitHub Variables

工作流文件需要以下 **5个额外的変数** （除了已有的 ACR_NAME 和 RESOURCE_GROUP）：

| Variable Name | 用途 | 示例值 |
|---|---|---|
| `AZURE_CLIENT_ID` | Web 应用的 Entra ID 应用 Client ID | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_TENANT_ID` | Azure 租户 ID | `87654321-4321-4321-4321-abcdef123456` |
| `AZURE_REDIRECT_URI` | OAuth 重定向 URI（web 应用 URL） | `https://todomanagement-web.abc123.japaneast.azurecontainerapps.io` |
| `API_PROXY_TARGET` | Web 容器代理到 internal API 的上游地址 | `https://todomanagement-api.abc123.japaneast.azurecontainerapps.io` |
| `USER_ASSIGNED_IDENTITY_CLIENT_ID` | 用户分配托管标识 Client ID | `12345678-1234-1234-1234-111111111111` |

### 第2步：获取这些值

#### 获取 AZURE_CLIENT_ID 和 AZURE_TENANT_ID

1. 打开 [Azure Portal](https://portal.azure.com)
2. 导航到：**Microsoft Entra ID** → **App registrations**
3. 如果没有现有的应用，需要创建新应用：
   - 点击 **+ New registration**
   - Name: `Todo Management Web` 
   - Supported account types: 按需选择
   - Redirect URI:
     - Platform: **Single-page application (SPA)**
     - URI: 稍后部署后补充（先输入 `http://localhost:5173`）
   - 点击 **Register**

4. 复制以下值：
   - **AZURE_CLIENT_ID**: 复制 **Application (client) ID**
   - **AZURE_TENANT_ID**: 复制 **Directory (tenant) ID**

#### 获取 AZURE_REDIRECT_URI

1. 部署后，Container App 会获得一个公共 URL
2. 方法A - 从 Azure Portal 获取：
   - 打开 Azure Portal → 资源组 → `rg-todomanagement-dev`
   - 找到 Container App `todomanagement-web`
   - 点击进入，复制 **Application Url** 中的完整 HTTPS URL

3. 方法B - 使用 Azure CLI：
   ```powershell
   az containerapp show -n todomanagement-web -g rg-todomanagement-dev --query properties.configuration.ingress.fqdn -o tsv
   ```
   然后在前面加 `https://` 得到完整 URL

4. **重要**: 将此 URL 添加到 Azure Entra ID 应用：
   - Azure Portal → Microsoft Entra ID → App registrations → 你的应用
   - **Authentication** → **Platform configurations** → **Single-page application**
   - 添加 Redirect URI

#### 获取 API_PROXY_TARGET

类似地，部署 API Container App 后：
```powershell
# 方法1：使用 Azure CLI
az containerapp show -n todomanagement-api -g rg-todomanagement-dev --query properties.configuration.ingress.fqdn -o tsv

# 然后得到 API_PROXY_TARGET = https://<fqdn>
```

#### 获取 USER_ASSIGNED_IDENTITY_CLIENT_ID

1. 打开 Azure Portal → 搜索 **Managed Identities**
2. 或导航到：**所有资源** → 搜索你的资源组中的用户分配托管标识
3. 点击打开，复制 **Client ID**

或使用 Azure CLI：
```powershell
# 列出资源组中的托管标识
az identity list -g rg-todomanagement-dev

# 查看详细信息
az identity show -g rg-todomanagement-dev -n <identity-name> --query clientId -o tsv
```

---

### 第3步：在 GitHub 配置 Variables

#### 方式A：使用 PowerShell 脚本自动配置（推荐）

```powershell
# 进入项目目录
cd c:\work\Panasonic\PCO\GSOL\todomanagement

# 运行脚本（交互式）
.\infra\setup-github-variables-update.ps1 -GitHubRepo "your-org/todomanagement"

# 如果想完全自动化，需要提供 GitHub Token
$token = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # GitHub Personal Access Token
.\infra\setup-github-variables-update.ps1 `
  -GitHubRepo "your-org/todomanagement" `
  -GitHubToken $token `
  -AzureClientId "12345678-..." `
  -AzureTenantId "87654321-..." `
  -RedirectUri "https://todomanagement-web.abc.azurecontainerapps.io" `
   -ApiProxyTarget "https://todomanagement-api.abc.azurecontainerapps.io" `
  -UserAssignedIdentityClientId "12345678-..."
```

获取 GitHub Personal Access Token：
1. GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**
2. 点击 **Generate new token (classic)**
3. 选择 **repo** 权限（全选）
4. 生成并复制 token

#### 方式B：手动在 GitHub 配置

1. 打开你的 GitHub 仓库
2. 进入：**Settings** → **Secrets and variables** → **Variables**
3. 点击 **New repository variable**
4. 添加以下 5 个 Variables：

   **Variable 1:**
   - Name: `AZURE_CLIENT_ID`
   - Value: (复制 Azure App Registration 的 Client ID)
   
   **Variable 2:**
   - Name: `AZURE_TENANT_ID`
   - Value: (复制 Azure 租户 ID)
   
   **Variable 3:**
   - Name: `AZURE_REDIRECT_URI`
   - Value: (部署后的 web 应用完整 URL，例如 https://todomanagement-web.xxxxx.japaneast.azurecontainerapps.io)
   
   **Variable 4:**
   - Name: `API_PROXY_TARGET`
   - Value: (API 应用的完整 internal URL，例如 https://todomanagement-api.xxxxx.japaneast.azurecontainerapps.io)
   
   **Variable 5:**
   - Name: `USER_ASSIGNED_IDENTITY_CLIENT_ID`
   - Value: (用户分配托管标识的 Client ID)

---

### 第4步：验证配置

在 GitHub 查看变量是否已正确设置：

```bash
# 如果安装了 GitHub CLI
gh variable list -R your-org/todomanagement

# 应该看到类似输出：
# AZURE_CLIENT_ID                         12345678-1234-1234-1234-123456789abc
# AZURE_TENANT_ID                         87654321-4321-4321-4321-abcdef123456
# AZURE_REDIRECT_URI                      https://todomanagement-web.xxxxx.azurecontainerapps.io
# API_PROXY_TARGET                        https://todomanagement-api.xxxxx.azurecontainerapps.io
# USER_ASSIGNED_IDENTITY_CLIENT_ID        12345678-1234-1234-1234-111111111111
```

---

### 第5步：重新部署

1. 进入 GitHub 仓库
2. 打开 **Actions** 标签页
3. 选择 **Build and Deploy Web to ACR** 工作流
4. 点击 **Run workflow** → **Run workflow**

或推送代码触发自动部署：
```powershell
git add .
git commit -m "trigger deployment after setting GitHub variables"
git push
```

---

## 🔍 故障排查

### 仍然出现相同错误？

1. **确认变量值是否为空**：
   - GitHub Settings 中检查变量是否真的有值
   - 不要有多余的空格或换行

2. **检查工作流中的变量引用是否正确**：
   - 工作流应该使用 `${{ vars.VARIABLE_NAME }}`
   - 确认变量名没有拼写错误

3. **查看工作流运行日志**：
   - GitHub Actions → 选择失败的运行
   - 点击 **Deploy to Container App** 步骤
   - 查看具体的输出和错误信息

4. **容器应用日志**：
   ```powershell
   # 查看 Container App 的运行时日志
   az containerapp logs show -n todomanagement-web -g rg-todomanagement-dev --tail 100
   ```

5. **本地测试**：
   - 在本地运行 web 应用，验证环境变量：
   ```powershell
   cd src/web
   npm run dev
   # 检查浏览器控制台是否报错
   ```

---

## 📖 参考

- [Azure Entra ID App Registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
- [MSAL.js Configuration](https://github.com/AzureAD/microsoft-authentication-library-for-js)
- [GitHub Actions Variables](https://docs.github.com/en/actions/learn-github-actions/variables)
- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview)
