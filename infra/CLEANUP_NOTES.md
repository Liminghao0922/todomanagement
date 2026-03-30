# Bicep 文件合并 - 清理说明

## 已完成

✅ **main.bicep** 已包含所有资源：
- Virtual Network 和所有子网配置
- PostgreSQL Flexible Server 和 Private Endpoint
- Azure Container Registry 和 Private Endpoint  
- Container App Environment
- Container Apps (API 和 Web)
- Managed Identity
- Entra ID 配置
- 所有安全性配置

## 可删除的文件

以下文件已不再需要（其内容已合并到 main.bicep）：

### 不再使用的 Bicep 模块
- ❌ `container-app.bicep` - 内容已合并到 main.bicep
- ❌ `entra-auth.bicep` - 内容已合并到 main.bicep  
- ❌ `main-complete.bicep` - 备份文件，可删除

### 删除命令

```bash
# 使用 git 删除（推荐，保留历史记录）
git rm infra/container-app.bicep
git rm infra/entra-auth.bicep
git rm infra/main-complete.bicep
git commit -m "Remove separate Bicep modules - all merged into main.bicep"
git push origin main

# 或使用本地删除（简单方式）
rm infra/container-app.bicep
rm infra/entra-auth.bicep
rm infra/main-complete.bicep
```

## 验证

部署脚本已确认使用统一的 main.bicep：
- deploy.ps1 第 76 行：`--template-file "main.bicep"`
- deploy.sh 已更新为使用 main.bicep

## 好处

✅ 单一文件更容易维护  
✅ 所有资源在一个地方  
✅ 更容易理解完整的基础设施  
✅ 部署更简单  

## 结构

main.bicep 现在的结构：
```
1. 参数定义
2. 变量定义
3. 虚拟网络 + 子网
4. PostgreSQL + Private Endpoint
5. Container Registry + Private Endpoint
6. Managed Identity
7. Log Analytics
8. Container App Environment
9. Container Apps (API + Web)
10. Entra ID 配置
11. Outputs
```
