# Todo Management - Web 前端应用

Vue 3 + Vite + TypeScript + Pinia 全栈实战应用前端

## 技术栈

- **框架**：Vue 3 (Composition API)
- **构建**：Vite 4
- **语言**：TypeScript
- **状态管理**：Pinia
- **路由**：Vue Router 4
- **HTTP 客户端**：Axios

## 快速开始

```bash
npm install
npm run dev
```

访问 [http://localhost:5173](http://localhost:5173)

## 项目结构

```
src/
├── main.ts            # 应用入口
├── App.vue            # 根组件
├── index.html         # HTML 模板
├── vite.config.ts     # Vite 配置
├── router/
│   └── index.ts       # 路由定义
├── stores/
│   └── todoStore.ts   # Pinia 状态管理
├── api/
│   ├── http.ts        # Axios 实例
│   ├── todos.ts       # Todo API
│   ├── search.ts      # 搜索 API
│   └── ai.ts          # AI 服务 API
├── pages/
│   ├── TodosPage.vue           # Todos 管理
│   ├── SemanticSearchPage.vue  # 向量搜索
│   └── WeeklySummaryPage.vue   # 周报
└── types/
    └── index.ts       # TypeScript 类型定义
```

## 核心页面

### 1. Todos 管理页面 (TodosPage.vue)

- 列表展示
- 创建新 Todo
- 编辑 Todo
- 删除 Todo
- 标记完成

### 2. 语义搜索页面 (SemanticSearchPage.vue)

- 向量相似性搜索输入
- 搜索结果展示
- 结果排序和过滤

### 3. 周报生成页面 (WeeklySummaryPage.vue)

- 查看本周完成统计
- 生成 AI 摘要
- 导出为 Markdown

## API 代理设置

Vite 代理配置在 `vite.config.ts`：

```typescript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:7071',  // Azure Functions 本地端口
      changeOrigin: true,
    }
  }
}
```

## 环境变量

创建 `.env.local` (仅本地，不提交)：

```env
VITE_API_BASE_URL=http://localhost:7071/api
VITE_APP_TITLE=Todo Management Workshop
```

## 构建部署

```bash
# 生产构建
npm run build

# 本地预览
npm run preview
```

输出目录：`dist/`

## 开发指南

### 添加新的 API 调用

1. 在 `src/api/` 中创建服务文件
2. 导出异步函数
3. 在组件中导入使用

示例：

```typescript
// src/api/myFeature.ts
import { apiClient } from './http'

export async function myFeatureAPI(data: any) {
  const response = await apiClient.post('/api/my-feature', data)
  return response.data
}
```

### 添加新的 Pinia Store

```typescript
// src/stores/myStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useMyStore = defineStore('my', () => {
  const count = ref(0)
  
  return {
    count,
  }
})
```

### 添加新的路由

编辑 `src/router/index.ts`：

```typescript
{
  path: '/my-feature',
  component: () => import('@/pages/MyFeature.vue'),
  meta: { title: 'My Feature' }
}
```

## 样式指南

- 使用 **Tailwind CSS** 推荐（可选）
- 或使用 **CSS Modules**
- 避免全局样式污染

## 调试

### VS Code 调试

1. 安装 "Debugger for Firefox" 或 "Chrome Debugger" 扩展
2. F5 启动调试
3. 在代码中设置断点

### 浏览器 DevTools

- F12 打开开发者工具
- Network 标签跟踪 API 调用
- Console 查看日志
- Vue DevTools 检查组件状态

## 性能优化

- ✅ 代码分割（路由级别）
- ✅ 懒加载组件
- ✅ CDN 加速（生产部署）
- ✅ 资源压缩（Vite 自动）

## 常见问题

**Q: API 调用返回 CORS 错误？**  
A: 确保 Vite 代理配置正确，Functions 后端在 http://localhost:7071 运行

**Q: 文件修改后热更新不工作？**  
A: 检查 Vite 配置，某些文件可能需要手动刷新

**Q: TypeScript 类型错误？**  
A: 运行 `npm run lint` 检查，或查看 VS Code 中的错误

## 许可证

MIT

---

**相关文档**：[主 README](../../README.md)
