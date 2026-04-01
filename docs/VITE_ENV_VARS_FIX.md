# Vite 环境变量配置修复

## 📋 问题

部署后仍然出现错误：
```
AADSTS700038: 00000000-0000-0000-0000-000000000000 is not a valid application identifier.
```

## 🔍 根本原因

**Vite 是一个编译时工具，而不是运行时工具。**

- ✅ 代码正确使用了 `import.meta.env.VITE_AZURE_CLIENT_ID` 
- ❌ 但工作流在 Docker 构建时**没有传递这些环境变量**
- ❌ 环境变量默认值为 `00000000-0000-0000-0000-000000000000`
- ❌ 在运行时注入这些变量对 Vite 应用**无效**（变量已经在构建时编译进去了）

### Vite 应用的工作原理

```
GitHub Actions 工作流
    ↓
Docker 构建 (使用 npm run build)
    ↓ [环境变量必须在这一步设置]
    ↓
Vite 编译并将变量值烧入 HTML/JS
    ↓
生成的产物已经包含具体的变量值
    ↓
运行时 (Container App) - 太晚了！
    ↓ [这时环境变量注入没有效果]
```

## ✅ 解决方案

### 1. Dockerfile 修改
添加 `ARG` 指令并在构建时传递给 npm：

```dockerfile
ARG VITE_AZURE_CLIENT_ID
ARG VITE_AZURE_AUTHORITY
ARG VITE_AZURE_REDIRECT_URI
ARG VITE_API_BASE_URL

# Build Vue app with environment variables
RUN VITE_AZURE_CLIENT_ID=${VITE_AZURE_CLIENT_ID} \
    VITE_AZURE_AUTHORITY=${VITE_AZURE_AUTHORITY} \
    VITE_AZURE_REDIRECT_URI=${VITE_AZURE_REDIRECT_URI} \
    VITE_API_BASE_URL=${VITE_API_BASE_URL} \
    npm run build
```

### 2. GitHub Actions 工作流修改
在 ACR 构建步骤中添加 `build_args`：

```yaml
- name: Build and push image to ACR
  uses: Azure/acr-build@v1
  with:
    # ... 其他配置 ...
    build_args: |
      VITE_AZURE_CLIENT_ID=${{ vars.AZURE_CLIENT_ID }}
      VITE_AZURE_AUTHORITY=https://login.microsoftonline.com/${{ vars.AZURE_TENANT_ID }}
      VITE_AZURE_REDIRECT_URI=${{ vars.AZURE_REDIRECT_URI }}
            VITE_API_BASE_URL=/api
```

### 3. Container App 运行时

移除运行时无效的 `VITE_*` 注入，只保留 Web 反向代理需要的变量：

```yaml
--env-vars API_PROXY_TARGET="${{ vars.API_PROXY_TARGET }}" USER_ASSIGNED_IDENTITY_CLIENT_ID="${{ vars.USER_ASSIGNED_IDENTITY_CLIENT_ID }}"
```

这里的 `API_PROXY_TARGET` 指向 internal API Container App 的 ingress URL，而浏览器仍然只访问同源 `/api`。

## 🚀 部署步骤

1. 修改已完成：
   - ✅ `src/web/Dockerfile` - 添加了 ARG 和环境变量传递
   - ✅ `.github/workflows/build-deploy-web.yml` - 添加了 build_args

2. 提交更改：
   ```bash
   git add .
   git commit -m "fix: Pass Vite env vars during Docker build stage"
   git push origin main
   ```

3. GitHub Actions 会自动运行，现在会：
   - 在 Docker 构建时传递这些变量给 npm
   - Vite 会读取这些变量并编译进去
   - 最终的镜像包含正确的配置值

## 📊 验证

部署完成后，打开浏览器控制台检查：

```javascript
// 在浏览器控制台中，应该看到正确的值
console.log(import.meta.env.VITE_AZURE_CLIENT_ID)  // 应该是你的 Client ID，而不是全0
```

## 📚 参考资料

- [Vite Environment Variables](https://vite.dev/guide/env-and-mode)
- [Docker ARG and ENV](https://docs.docker.com/engine/reference/builder/#arg)
- [Azure/acr-build@v1 Documentation](https://github.com/Azure/acr-build)

## 常见问题

**Q: 为什么不能在运行时注入这些变量？**
A: Vite 将这些变量在构建时编译进了 JavaScript 文件。运行时环境变量对已编译的文件无效。这是所有前端打包器（Webpack、Parcel 等）的共同特性。

**Q: 如果需要运行时改变这些配置怎么办？**
A: 需要在运行时从 API 端点获取配置，而不是依赖环境变量。可以在 `src/main.ts` 中添加启动时配置加载逻辑。

**Q: 为什么代码中 import.meta.env 没有被替换？**
A: 确保所有变量都以 `VITE_` 前缀开头，否则 Vite 不会处理它们。
