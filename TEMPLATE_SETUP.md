# 🚀 Template Setup Guide - 自定义您的项目

欢迎使用 **Todo Management** GitHub Template！本指南将帮助您快速定制项目名称、资源组和 Azure 资源。

## 📋 Step 1: 确定您的项目参数

在开始之前，请决定以下信息：

| 参数 | 示例 | 说明 |
|------|------|------|
| `{{PROJECT_NAME}}` | `myapp`、`projectx` | 项目简称（小写字母和数字，无空格），用于资源命名 |
| `{{ENVIRONMENT}}` | `dev`、`staging`、`prod` | 环境标识 |
| `{{AZURE_REGION}}` | `japaneast`、`eastus`、`westeurope` | Azure 区域 |
| `{{PROJECT_TITLE}}` | `My Todo App`、`Project X Management` | 项目完整名称（可含空格），用于文档 |

## 🔍 Step 2: 搜索并替换占位符

### Option A: 使用 VS Code 全局替换

1. 打开项目根目录
2. 使用 **Ctrl+Shift+H** 打开"查找和替换"
3. 依次替换以下占位符：

| 查找 | 替换为 | 文件范围 |
|------|--------|---------|
| `{{PROJECT_NAME}}` | 你的项目名（例：`myapp`） | `**/*` |
| `{{ENVIRONMENT}}` | 环境（例：`dev`） | `**/*` |
| `{{AZURE_REGION}}` | 区域（例：`eastus`） | `infra/parameters.json` |
| `{{PROJECT_TITLE}}` | 项目标题 | `README.md`, `docs/**` |

### Option B: 使用命令行（PowerShell / Bash）

**PowerShell:**
```powershell
$projectName = "myapp"
$environment = "dev"
$region = "japaneast"
$projectTitle = "My Project"

# 查找所有需要替换的文件
Get-ChildItem -Recurse -Include "*.md", "*.json", "*.yml", "*.bicep" |
  ForEach-Object {
    (Get-Content $_.FullName) `
      -replace '{{PROJECT_NAME}}', $projectName `
      -replace '{{ENVIRONMENT}}', $environment `
      -replace '{{AZURE_REGION}}', $region `
      -replace '{{PROJECT_TITLE}}', $projectTitle |
      Set-Content $_.FullName
  }
```

**Bash:**
```bash
PROJECT_NAME="myapp"
ENVIRONMENT="dev"
REGION="japaneast"
PROJECT_TITLE="My Project"

find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.bicep" \) |
  while read file; do
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$file"
    sed -i "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" "$file"
    sed -i "s/{{AZURE_REGION}}/$REGION/g" "$file"
    sed -i "s/{{PROJECT_TITLE}}/$PROJECT_TITLE/g" "$file"
  done
```

## 📝 Step 3: 验证替换

替换后，检查以下文件确保没有遗漏：

```bash
# 搜索遗留的占位符
grep -r "{{PROJECT_NAME}}" .
grep -r "{{ENVIRONMENT}}" .
grep -r "{{AZURE_REGION}}" .
grep -r "{{PROJECT_TITLE}}" .
```

如果没有输出，说明替换完成 ✅

## 🔐 Step 4: 更新敏感信息

### infra/parameters.json

修改以下值（**不要提交到 Git**）：

```json
{
  "postgresqlAdminPassword": {
    "value": "YOUR_STRONG_PASSWORD_HERE"  // 改为强密码 (8+ 字符)
  }
}
```

> **⚠️ 重要**：生产环境中，使用 Azure Key Vault 管理密码，不要硬编码在代码中。

### GitHub Secrets & Variables

参考 `docs/GITHUB_CONFIG_SETUP.md` 配置以下 GitHub Secrets：

- `AZURE_CREDENTIALS` - Azure Service Principal JSON

及以下 Variables：

- `ACR_NAME` - 已从占位符自动生成
- `RESOURCE_GROUP` - 格式：`rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}`
- `POSTGRES_SERVER` - 从 Azure 部署输出获取
- `POSTGRES_DB` - `tododb`（或自定义）
- `POSTGRES_USER` - 授权给 Entra ID 身份的用户
- `AZURE_CLIENT_ID` - 应用注册客户端 ID
- `AZURE_TENANT_ID` - 租户 ID
- `AZURE_REDIRECT_URI` - Web App 完整 URL
- `API_BASE_URL` - API 完整 URL
- `USER_ASSIGNED_IDENTITY_CLIENT_ID` - 托管身份 Client ID

## 🚀 Step 5: 本地验证

替换完成后，在本地测试以确保一切正常：

### 验证 README

```bash
cat README.md | grep -i "{{PROJECT_TITLE}}"  # 应该返回空
```

### 验证 Bicep 参数

```bash
cat infra/parameters.json
# 确保 projectName 已更新为你的项目名
```

### 验证 GitHub Actions

```bash
cat .github/workflows/build-deploy-api.yml | grep "ACR_NAME\|RESOURCE_GROUP"
# 确保变量引用正确
```

## 📦 完成清单

- [ ] 决定了 4 个项目参数（PROJECT_NAME、ENVIRONMENT、AZURE_REGION、PROJECT_TITLE）
- [ ] 使用 VS Code 或命令行替换了所有占位符
- [ ] 验证没有遗留的 `{{}}` 占位符
- [ ] 更新了 `infra/parameters.json` 中的 PostgreSQL 密码
- [ ] 提交代码到 main 分支
- [ ] 参考 `docs/GITHUB_CONFIG_SETUP.md` 配置了 GitHub Secrets 和 Variables
- [ ] 运行 `infra/deploy.sh` 或 `infra/deploy.ps1` 部署基础设施

## ✅ 下一步

完成上述步骤后：

1. **本地运行**：按 `README.md` 的"本地运行"部分进行测试
2. **部署基础设施**：按 `README.md` 的"Azure Cloud Shell 部署"进行部署
3. **配置 CI/CD**：触发 GitHub Actions 工作流自动构建和部署

## 🆘 常见问题

### Q: 我替换时不小心改了源代码逻辑怎么办？

**A:** 用 Git 恢复：
```bash
git checkout -- src/
```
然后重新仅替换配置文件。

### Q: 项目名称中能否使用大写字母或特殊字符？

**A:** **不建议**。Azure 资源名称有严格限制：
- ACR 名称：仅小写字母和数字，无连字符
- 资源组：允许字母、数字、连字符
- 建议统一使用小写字母和数字（如 `myapp123`）

### Q: 如何更改 Azure 区域？

**A:** 编辑 `infra/parameters.json`：
```json
{
  "location": {
    "value": "eastus"  // 改为目标区域
  }
}
```

### Q: 部署后发现资源名称有错误，怎么办？

**A:** 
1. 删除资源组：`az group delete --name rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}`
2. 修正参数和占位符
3. 重新运行 `infra/deploy.sh`

## 📚 相关文档

- [README.md](./README.md) - 项目概览与部署指南
- [docs/ARCHITECTURE_GUIDE.md](./docs/ARCHITECTURE_GUIDE.md) - 基础设施架构
- [docs/GITHUB_CONFIG_SETUP.md](./docs/GITHUB_CONFIG_SETUP.md) - GitHub Secrets 配置
- [infra/README.md](./infra/README.md) - Bicep 部署详情

---

**有问题？** 提交 Issue 或查看 GitHub Discussions！
