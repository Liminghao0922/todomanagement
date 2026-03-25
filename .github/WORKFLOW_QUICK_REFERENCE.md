# GitHub Workflow 快速参考

## 📁 文件位置
- `.github/workflows/build-deploy.yml` - 基础版（单环境）
- `.github/workflows/build-deploy-multi-env.yml` - 多环境版（推荐）

## 🔄 工作流程图

```
代码提交到GitHub (main/develop/staging)
        ↓
✅ Checkout 代码
        ↓
✅ 设置Docker Buildx
        ↓
✅ 登录到ACR
        ↓
✅ 提取元数据（版本标签等）
        ↓
✅ 构建Docker镜像
        ↓
✅ 推送镜像到ACR
        ↓
✅ Azure登录
        ↓
✅ 获取环境变量（dev/staging/prod）
        ↓
✅ 更新Container App镜像
        ↓
✅ 验证部署状态
        ↓
✅ 发送Slack通知（可选）
        ↓
完成 ✅
```

## 📢 镜像标签策略

Workflow会自动为镜像创建以下标签：

| 触发条件 | 镜像标签 | 说明 |
|---------|---------|------|
| main分支提交 | `latest`, `main-<short-sha>` | 生产环境 |
| develop分支提交 | `develop-<short-sha>` | 开发环境 |
| staging分支提交 | `staging-<short-sha>` | 测试环境 |
| 发布版本 (tag) | `v1.0.0` | 版本标签 |

**示例：**
```
acrtodemanagementixxxxx.azurecr.io/todomanagement/api:latest
acrtodemanagementixxxxx.azurecr.io/todomanagement/api:main-a1b2c3d
acrtodemanagementixxxxx.azurecr.io/todomanagement/api:develop-e4f5g6h
```

## 🎯 部署触发条件

### 什么时候会触发构建？
✅ 代码推送到tracked分支
✅ Pull Request创建
✅ 手动触发 (Actions页面 → Run workflow)
✅ `.github/workflows/build-deploy*.yml` 文件变更

### 什么时候会部署到Container App？
✅ **基础版：** main分支的push
✅ **多环境版：** 
  - main分支 → prod
  - staging分支 → staging
  - develop分支 → dev
  - 手动选择环境

❌ Pull Request 不会部署（仅构建）

## 🚀 手动部署

### 方式1：通过GitHub UI
1. 进入仓库 → **Actions** 标签
2. 选择 workflow: **"Build and Deploy (Multi-Environment)"**
3. 点击 **"Run workflow"** 按钮
4. 选择目标环境
5. 点击 **"Run workflow"**

### 方式2：使用GitHub CLI
```bash
# 查看所有workflows
gh workflow list

# 手动触发workflow（仅适用于支持的版本）
gh workflow run build-deploy-multi-env.yml -f deploy_env=prod
```

## 📊 监控构建和部署

### 查看实时日志
1. 进入仓库 → **Actions** 标签
2. 点击最新的 workflow run
3. 展开具体的 job (如 "build-and-push" 或 "deploy")
4. 查看实时日志

### 查看部署历史
```
Actions → 选择workflow → 查看所有runs
```

每个run显示：
- ✅ 成功 (绿色)
- ❌ 失败 (红色)  
- ⏳ 进行中 (黄色)
- ⊘ 跳过 (灰色)

## 🔍 常见问题排查

### Q: 为什么构建成功但镜像没有推送到ACR？
**A:** 检查push条件。默认仅在以下情况推送：
- 非Pull Request
- 带有标签（如main-xxxxx）
- GitHub Secrets配置正确

### Q: 为什么Container App更新失败？
**A:** 检查：
1. Azure Credentials Secret配置是否正确
2. 服务主体是否有足够权限
3. Container App名称和资源组名称是否正确
4. 网络连接是否正常

### Q: 如何查看Azure登录错误？
**A:** 在 workflow 日志中查看 "Azure Login" 步骤的详细错误信息。

### Q: 镜像太大，上传很慢？
**A:** 检查Dockerfile的多阶段构建是否优化。当前Dockerfile已优化，但可以：
- 删除不必要的依赖
- 使用alpine基础镜像（若兼容）
- 添加 `.dockerignore` 排除不需要的文件

## 🛡️ 安全最佳实践

✅ **已实现的安全措施：**
- 使用GitHub Secrets存储敏感信息
- 多阶段Docker构建减小镜像大小
- Health check enabled
- Container App更新时使用最新镜像
- Slack通知可跟踪部署情况

✅ **建议的额外措施：**
1. 定期更新Docker基础镜像
2. 使用ACR令牌而非管理员密码
3. 启用环境保护规则（仅某些users可部署prod）
4. 定期审计Secrets和权限

## 📈 性能优化

### Docker构建缓存
- 使用 `type=gha` 缓存加快构建速度
- 首次构建：~5-10分钟
- 后续构建：~2-3分钟（使用缓存）

### 并行步骤
- build-and-push 和 deploy 可并行进行
- deploy 等待 build-and-push 完成

### 镜像大小
当前镜像大小约：~200-300MB (Python 3.11 slim + 依赖)

## 🔐 Secrets管理

### 查看已配置的Secrets
```bash
gh secret list
```

### 更新Secret
```bash
gh secret set SECRET_NAME
# 然后在提示符中粘贴新值
```

### 删除Secret
```bash
gh secret delete SECRET_NAME
```

### 轮换认证信息
推荐每6-12个月轮换一次：
1. 创建新的服务主体
2. 测试新的Credentials
3. 更新GitHub Secrets
4. 删除旧的服务主体

## 📱 通知配置

### Slack通知（可选）
当前workflow支持Slack通知成功和失败事件。

**配置步骤：**
1. 创建Slack Webhook (见WORKFLOW_SETUP.md)
2. 添加 `SLACK_WEBHOOK` Secret
3. Workflow会自动在deployment成功/失败时通知

**通知包含信息：**
- 部署状态 (✅/❌)
- 环境名称
- 提交ID
- 镜像标签

## 💡 高级用法

### 跳过工作流执行
在commit信息中添加以下其中之一：
```
[skip ci]
[skip github]
```

示例：
```bash
git commit -m "Update README [skip ci]"
```

### 多个不同的部署
可以创建额外的workflow文件在 `.github/workflows/` 目录中：
```
.github/workflows/
├── build-deploy-multi-env.yml  ← 主工作流
├── build-deploy.yml             ← 基础版本
├── security-scan.yml            ← 安全扫描（可选）
└── performance-test.yml         ← 性能测试（可选）
```

## 📚 参考资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Azure CLI 容器应用](https://learn.microsoft.com/zh-cn/cli/azure/containerapp)
- [Docker最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## 📞 获取帮助

如果workflow失败：
1. 查看完整的日志输出
2. 检查GitHub Secrets配置
3. 验证Azure资源是否存在
4. 确保Docker文件有效

失败日志通常显示具体的错误信息，便于诊断。
