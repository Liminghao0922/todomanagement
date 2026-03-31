# Entra ID Authentication Setup Guide

## 概述

本应用已集成 Entra ID (Azure Active Directory) 认证和 AI 聊天助手。

## 功能

### 1. Entra ID 认证
- ✅ 集成了 MSAL (Microsoft Authentication Library)
- ✅ 支持登录/登出
- ✅ 显示用户名和头像
- ✅ 安全的令牌管理

### 2. AI 聊天侧边栏
- ✅ Copilot 风格的聊天界面
- ✅ 右下角浮动按钮
- ✅ 实时消息交互
- ✅ 打字动画和加载状态

## 配置步骤

### 步骤 1: 在 Azure Portal 注册应用

1. 访问 [Azure Portal](https://portal.azure.com)
2. 转到 **Microsoft Entra ID** → **App registrations**
3. 点击 **+ New registration**
4. 填写以下信息：
   - **Name**: `Todo Management App` (或你喜欢的名称)
   - **Supported account types**: 选择适合你的选项
   - **Redirect URI**: 
     - **Platform**: Single-page application (SPA)
     - **URI**: `http://localhost:5173` (开发环境)
     - **URI**: `https://yourdomain.com` (生产环境)
5. 点击 **Register**

### 步骤 2: 获取客户端 ID 和租户 ID

1. 在应用注册页面，复制 **Application (client) ID**
2. 复制 **Directory (tenant) ID**

### 步骤 3: 配置环境变量

在 `src/web/.env.local` 中设置：

```env
VITE_AZURE_CLIENT_ID=your-client-id-here
VITE_AZURE_AUTHORITY=https://login.microsoftonline.com/your-tenant-id-here
VITE_AZURE_REDIRECT_URI=http://localhost:5173
```

### 步骤 4: 可选 - 配置 API 权限

如果需要访问 Microsoft Graph API，在应用注册中：

1. 转到 **API permissions**
2. 点击 **+ Add a permission**
3. 选择 **Microsoft Graph**
4. 选择 **Delegated permissions**
5. 添加需要的权限（例如 `User.Read`）
6. 点击 **Grant admin consent**

## 使用

### 登录/登出

1. 点击右上角的 **🔐 Login** 按钮
2. 在弹出的 Microsoft 登录窗口中输入凭证
3. 登录后，右上角显示用户名
4. 点击 **🚪 Logout** 登出

### 使用聊天助手

1. 点击右下角的 **💬** 按钮打开聊天侧边栏
2. 输入消息，按 Enter 或点击 **➤** 发送
3. AI 助手会实时响应
4. 点击 **🗑️** 清除聊天历史
5. 点击 **✕** 关闭聊天面板

## 文件结构

```
src/web/src/
├── api/
│   ├── auth.ts           # MSAL 配置和初始化
│   ├── chat.ts           # 聊天 API 服务
│   ├── http.ts           # HTTP 客户端
│   └── ...
├── stores/
│   ├── authStore.ts      # 认证状态管理
│   ├── chatStore.ts      # 聊天状态管理
│   └── ...
├── components/
│   └── ChatSidebar.vue   # 聊天侧边栏组件
└── App.vue               # 主应用，包含认证 UI
```

## 注意事项

### 安全性

- ✅ 使用 MSAL 安全处理令牌
- ✅ 令牌存储在 localStorage（可配置）
- ✅ 建议生产环境使用 HTTPS
- ✅ 建议配置 CORS 和 CSP

### 聊天 API

聊天功能需要后端 API 支持：

- `POST /api/chat` - 发送聊天消息
- `GET /api/weeklySummary/{userId}` - 获取周报总结
- `POST /api/search/semantic` - 语义搜索

确保后端已实现这些端点。

### 故障排除

#### 登录失败
- 检查 `VITE_AZURE_CLIENT_ID` 和租户 ID 是否正确
- 确保重定向 URI 与 Azure Portal 配置相同
- 检查浏览器控制台的错误信息

#### 聊天不工作
- 确保后端 API 正在运行
- 检查 CORS 配置
- 查看浏览器开发者工具中的网络请求

#### 令牌过期
- MSAL 自动处理令牌刷新
- 如果出现 401 错误，通常是权限问题

## 相关链接

- [Microsoft Entra ID 文档](https://learn.microsoft.com/zh-cn/entra/)
- [MSAL.js 文档](https://learn.microsoft.com/zh-cn/entra/identity-platform/msal-overview)
- [Azure Portal](https://portal.azure.com)

## 下一步

- [ ] 在后端实现聊天 API 端点
- [ ] 配置 CORS 和安全头
- [ ] 添加更多 API 权限（如需）
- [ ] 部署到生产环境
- [ ] 配置自定义域名
