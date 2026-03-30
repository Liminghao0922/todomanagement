# Template 迁移指南

本文档说明如何从原始 `todomanagement` 项目升级到新的 Template 版本。

## 变更总结

### 新增文件

| 文件 | 说明 |
|------|------|
| `TEMPLATE_SETUP.md` | 🆕 详细的 Template 自定义指南 |
| `.github/TEMPLATE.md` | 🆕 使用 Template 后显示的欢迎指南 |
| `.github/TEMPLATE_CHECKLIST.md` | 🆕 快速核对表 |
| `TEMPLATE_MIGRATION.md` | 🆕 本文件 |

### 修改文件

| 文件 | 变更 | 原因 |
|------|------|------|
| `README.md` | 顶部添加 `{{PROJECT_TITLE}}` 占位符和 Template 提示 | 适配 Template Repository |
| `infra/parameters.json` | 添加占位符 | 支持项目自定义 |
| `.github/workflows/build-deploy-api.yml` | 添加 `{{PROJECT_NAME}}`、`{{ENVIRONMENT}}` 占位符 | 支持项目自定义 |
| `.github/workflows/build-deploy-web.yml` | 添加 `{{PROJECT_NAME}}`、`{{ENVIRONMENT}}` 占位符 | 支持项目自定义 |
| `infra/README.md` | 添加占位符和示例 | 支持项目自定义 |
| `infra/deploy.ps1` | 添加占位符注释和默认值 | 支持项目自定义 |
| `infra/deploy.sh` | 添加占位符变量 | 支持项目自定义 |
| `docs/GITHUB_CONFIG_SETUP.md` | 添加 Template 提示和占位符示例 | 支持项目自定义 |

## 占位符列表

以下是所有引入的占位符及其含义：

| 占位符 | 示例 | 使用位置 |
|--------|------|---------|
| `{{PROJECT_NAME}}` | `myapp`、`projectx` | 资源命名、容器名称、变量值 |
| `{{ENVIRONMENT}}` | `dev`、`staging`、`prod` | 资源名称后缀 |
| `{{AZURE_REGION}}` | `japaneast`、`eastus` | 区域选择 |
| `{{PROJECT_TITLE}}` | `My Todo App` | 文档标题 |

## 对现有用户的影响

### ✅ 无影响的方面

- 源代码逻辑完全不变（`src/api/`、`src/web/`）
- Bicep 模板功能不变，仅添加了参数
- 数据库 schema 不变
- API 端点不变

### ⚠️ 需要注意的方面

如果您已经部署了此项目并想升级到 Template 版本：

1. **新增的文档文件** - 不影响部署，仅为指导用途
2. **README 变更** - 仅文本变更，不影响功能
3. **占位符添加** - 不需要立即替换，现有配置继续有效
   - 如果您之前使用的是 `rg-todomanagement-dev` 资源组，继续正常工作
   - 仅当您想迁移到新的项目时才需要替换占位符

## 迁移步骤（如需升级）

### 方案 A：手动拉取最新代码

```bash
git remote add upstream https://github.com/YOUR_ORG/todomanagement.git
git fetch upstream
git merge upstream/main

# 解决冲突（如果有）
git add .
git commit -m "merge: upgrade to template version"
git push origin main
```

### 方案 B：保持现有配置，仅拉取新文档

```bash
# 拉取新文件
git fetch origin

# 合并特定文件
git checkout origin/main -- TEMPLATE_SETUP.md
git checkout origin/main -- .github/TEMPLATE.md
git checkout origin/main -- .github/TEMPLATE_CHECKLIST.md

git add .
git commit -m "docs: add template documentation"
git push origin main
```

### 方案 C：从新 Template 创建新项目

```bash
# 1. 在 GitHub 上使用 "Use this template" 创建新仓库
# 2. 按 TEMPLATE_SETUP.md 自定义项目名称
# 3. 保留旧项目作为参考
```

## 常见问题

### Q: 升级后我现有的部署会受影响吗？

**A:** 不会。新文件仅为指导用途，不影响现有部署。现有资源组、Container Apps、ACR 等继续正常工作。

### Q: 我可以忽略占位符吗？

**A:** 可以。如果您不想创建新项目，占位符不会对您造成任何影响。仅当您创建新项目时才需要替换占位符。

### Q: 如何在现有项目中应用 Template 自定义？

**A:** 如果您想为现有项目应用 Template 自定义步骤：

1. 阅读 `TEMPLATE_SETUP.md`
2. 决定新的项目参数（或保持现有的）
3. 如需更改，按指南进行占位符替换
4. 推送变更，GitHub Actions 会自动部署

### Q: 我是否需要立即升级？

**A:** 不需要。此升级完全向后兼容。您可以选择：
- 继续使用现有配置（无需变更）
- 在方便时升级并享受 Template 功能
- 创建新项目时使用 Template

## 反馈

如有任何问题或建议，请：

1. 查看 [TEMPLATE_SETUP.md](./TEMPLATE_SETUP.md) 的常见问题部分
2. 在 GitHub Issues 中报告
3. 提交 Pull Request 改进文档

---

**Happy deploying!** 🚀
