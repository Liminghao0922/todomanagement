# Template 快速核对表

使用此 checklist 来追踪您的 Template 自定义进度。

## Phase 1: 决定项目参数

- [ ] 项目简称 (`{{PROJECT_NAME}}`): _______________
- [ ] 环境标识 (`{{ENVIRONMENT}}`): _______________
- [ ] Azure 区域 (`{{AZURE_REGION}}`): _______________
- [ ] 项目标题 (`{{PROJECT_TITLE}}`): _______________

## Phase 2: 搜索替换占位符

使用 VS Code **查找和替换** (Ctrl+Shift+H) 或命令行脚本（见 TEMPLATE_SETUP.md）：

- [ ] 替换 `{{PROJECT_NAME}}`
- [ ] 替换 `{{ENVIRONMENT}}`
- [ ] 替换 `{{AZURE_REGION}}`
- [ ] 替换 `{{PROJECT_TITLE}}`

## Phase 3: 验证没有遗留占位符

运行此命令确保替换完毕：
```bash
grep -r "{{" . --include="*.md" --include="*.json" --include="*.yml" --include="*.bicep" 2>/dev/null || echo "✓ 无占位符"
```

- [ ] 验证完成，无遗漏

## Phase 4: 敏感信息配置

- [ ] 更新 `infra/parameters.json` 中的 `postgresqlAdminPassword`
- [ ] 决定了 Azure Service Principal（用于 GitHub Actions）
- [ ] 记录了 Service Principal 的凭证 JSON

## Phase 5: Git 提交

```bash
git add .
git commit -m "chore: customize template for {{PROJECT_NAME}}"
git push origin main
```

- [ ] 本地提交完成
- [ ] 推送到 GitHub 完成

## Phase 6: GitHub Secrets & Variables 配置

参考 `docs/GITHUB_CONFIG_SETUP.md`：

### Variables
- [ ] `ACR_NAME` - 从部署输出获取
- [ ] `RESOURCE_GROUP` - `rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}`
- [ ] `POSTGRES_SERVER` - 部署后获取
- [ ] `POSTGRES_DB` - `tododb`（或自定义）
- [ ] `POSTGRES_USER` - 授权的 Entra 身份
- [ ] `AZURE_CLIENT_ID` - 应用注册 Client ID
- [ ] `AZURE_TENANT_ID` - 租户 ID
- [ ] `AZURE_REDIRECT_URI` - Web App URL
- [ ] `API_BASE_URL` - API App URL
- [ ] `USER_ASSIGNED_IDENTITY_CLIENT_ID` - 托管身份 Client ID

### Secrets
- [ ] `AZURE_CREDENTIALS` - Service Principal JSON

## Phase 7: 本地测试

```bash
# API 测试
cd src/api
python -m venv .venv
.\.venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000

# Web 测试（新终端）
cd src/web
npm install
npm run dev
```

- [ ] API 启动成功，health check 返回 200
- [ ] Web 启动成功，访问 http://localhost:5173 无错误

## Phase 8: 部署基础设施

```bash
cd infra
# Windows
.\deploy.ps1 -ResourceGroupName "rg-{{PROJECT_NAME}}-{{ENVIRONMENT}}" -Location "{{AZURE_REGION}}"

# Linux/macOS
chmod +x deploy.sh
./deploy.sh
```

- [ ] 部署成功，记录输出到 `deployment-outputs.json`
- [ ] PostgreSQL 服务器已创建
- [ ] ACR 已创建
- [ ] Container App Environment 已创建

## Phase 9: GitHub Actions 触发

```bash
# 推送代码触发工作流
git add .
git commit -m "trigger: deploy after template setup"
git push origin main
```

- [ ] Build and Deploy API 工作流运行成功
- [ ] Build and Deploy Web 工作流运行成功
- [ ] 镜像成功推送到 ACR
- [ ] Container Apps 成功部署

## Phase 10: 部署验证

```bash
# 测试 API 健康检查
curl https://<api-container-app-url>/health

# 访问前端
https://<web-container-app-url>
```

- [ ] API 健康检查返回 200
- [ ] Web 前端可访问，无错误
- [ ] Entra ID 登录功能正常

## ✅ 完成！

所有步骤完成后，您的项目已准备就绪。

### 常见后续步骤：

- 配置 GitHub Webhooks（可选）
- 设置 Azure 监控告警
- 配置自定义域名（如需）
- 启用 Azure DevOps 集成（如需）

---

**需要帮助？** 参考 TEMPLATE_SETUP.md 或提交 Issue。
