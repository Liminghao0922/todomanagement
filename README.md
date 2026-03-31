# Todo Management

全栈示例：FastAPI + PostgreSQL 后端与 Vue 3 + Vite 前端，使用 Azure Container Apps、ACR、Entra ID 托管身份和私网访问实现零明文凭据架构。

## 架构速览
- 容器：`todomanagement-api`（FastAPI）与 `todomanagement-web`（Vite/Vue）。
- 基础设施：VNet 私有子网、PostgreSQL Flexible Server（Entra ID）、ACR 私有端点、Container Apps Environment、Log Analytics、用户分配托管身份。
- CI/CD：GitHub Actions 构建镜像推送 ACR，并通过 `az containerapp up` 滚动部署。
- 参考：`docs/ARCHITECTURE_GUIDE.md` 与 `images/01.Architecture.png`。

## 仓库结构
- `src/api`：FastAPI 服务（可 SQLite 本地、PostgreSQL 生产）。
- `src/web`：Vue 3 SPA（MSAL 登录、Todo/搜索/周报功能）。
- `infra`：Bicep 模板、部署脚本、参数文件。
- `docs`：Entra 配置、GitHub 变量、Vite 构建等指南。

## 本地运行
前置：Python 3.11、pip、Node 18+、npm。

API
```powershell
cd src\api
copy .env.local.example .env.local  # 本地可保持 DATABASE_TYPE=sqlite
python -m venv .venv; .\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
# 健康检查: http://localhost:8000/health
```
若使用本地 PostgreSQL，设置 `.env.local` 的 `DATABASE_TYPE=postgresql` 及 `POSTGRES_*`。

Web
```powershell
cd src\web
copy .env.example .env.local
# 本地后端地址
set VITE_API_BASE_URL=http://localhost:8000
npm install
npm run dev  # http://localhost:5173
```
生产构建：`npm run build`，输出在 `dist/`。

## 使用 Azure Cloud Shell 部署
要求：订阅 Contributor/Owner 权限。Cloud Shell（Bash）自带 Azure CLI/Bicep。

1) 打开 Azure Cloud Shell（Bash），选择目标订阅：`az account show` / `az account set --subscription <id>`  
2) 拉取代码并进入基础设施目录：
```bash
git clone <your-repo-url>
cd todomanagement/infra
```
3) 如需修改区域或环境，在 `parameters.json` 中调整 `location`、`environment` 等参数。  
4) 部署基础设施（RG、VNet、PostgreSQL、ACR、Container Apps 环境、私有 DNS）：
```bash
chmod +x deploy.sh
./deploy.sh
```
5) 记录部署输出（PostgreSQL 主机名/DB、ACR 名称、Container Apps Environment、托管身份等）。  
6) 在 GitHub 仓库配置 Secrets/Variables（详见 `docs/GITHUB_CONFIG_SETUP.md` 与 `docs/VITE_ENV_VARS_FIX.md`）：
   - Variables：`ACR_NAME`、`RESOURCE_GROUP`、`POSTGRES_SERVER`、`POSTGRES_DB`（默认 `tododb`）、`POSTGRES_USER`（授予权限的 Entra 身份）、`AZURE_CLIENT_ID`、`AZURE_TENANT_ID`、`AZURE_REDIRECT_URI`、`API_BASE_URL`、`USER_ASSIGNED_IDENTITY_CLIENT_ID` 等。
   - Secret：`AZURE_CREDENTIALS`（Service Principal JSON）。
7) 触发 GitHub Actions（`build-deploy-api.yml`、`build-deploy-web.yml`）通过 `workflow_dispatch` 或推送到 main。工作流会构建镜像、推送 ACR 并部署 Container Apps。  
8) 部署后，在 Entra ID 应用中加入新的 Web 重定向 URI（Container App URL），并验证：
```
https://<api-fqdn>/health
https://<web-fqdn>/            # 前端
```

## 参考与故障排查
- `docs/ARCHITECTURE_GUIDE.md`：完整拓扑与零信任说明  
- `docs/GITHUB_VARIABLES_TROUBLESHOOTING.md`：变量缺失导致的 AADSTS700038 等错误  
- `infra/DEPLOYMENT_CHECKLIST.md`：部署核对清单  
- `docs/VITE_ENV_VARS_FIX.md`：Vite 编译期变量传递说明
