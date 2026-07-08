# Todo Management GUI 部署指南

[English](DEPLOY_GUIDE_GUI.md) | [简体中文](DEPLOY_GUIDE_GUI-zh_CN.md) | [日本語](DEPLOY_GUIDE_GUI-ja_JP.md)

本指南说明了面向初学者的、基于 Azure Portal 的 GUI 优先部署路径。适用于培训课程或首次部署。

预计耗时: 45 到 60 分钟。

---

## 术语统一标准 (EN/JA/ZH)

三语版本中统一使用以下术语:

- Microsoft Entra ID
- Azure Container Apps Environment
- Instructor-provided container image

说明:

- 在 API Container App 的环境变量中，`USER_ASSIGNED_IDENTITY_CLIENT_ID` 表示用于 PostgreSQL 认证的用户分配托管标识 Client ID。
- Web 登录使用讲师提供的或本指南中创建的 Microsoft Entra ID 应用 Client ID 和 tenant/authority 值。

---

## 工作流概述

本指南包含以下阶段:

1. **阶段 1: 准备** - 确认讲师提供的容器镜像和值
2. **阶段 2: Azure 基础设施设置** (通过 Portal) - 创建所需 Azure 资源并部署已准备好的镜像
3. **阶段 3: 验证** - 添加 Redirect URI 并测试已部署的应用

有关 IaC/Bicep 路径，请参阅 `DEPLOY_GUIDE.md` (高级路径)。

---

## 先决条件

- Azure 订阅权限: `Owner`
- 讲师 ACR 上的 Owner 角色，这样当前登录的 Azure Portal 账号才能给 Container App 的 system-assigned identity 授予 `AcrPull`
- Microsoft Entra ID 应用注册创建权限:
  - `Application Administrator`、`Cloud Application Administrator` 或 `Application Developer` 角色
  - 如果您的组织允许所有用户注册应用 (默认设置)，则不需要特殊角色
  - 参考: [Least privileged roles by task - Microsoft Entra ID (MS Learn)](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-by-task)

从讲师处收集以下容器镜像信息:

- API image name and tag
- Web image name and tag
- Registry login server

培训参与者重要提示:

- 开始前准备好名称、区域和所需 ID
- 本初学者指南不需要在培训中使用 GitHub Actions、Repository variables，也不需要构建容器镜像
- 讲师必须提前准备并测试适用于课堂配置的镜像。特别是简化后的 Web 镜像必须支持通过 Container App 环境变量配置 Microsoft Entra ID。

---

## 阶段 1: 准备

> 预计耗时: 5 分钟

创建 Azure 资源前，请先从讲师处收集镜像和配置值。

| 项目 | 示例 | 说明 |
| ---- | ---- | ---- |
| API image | `instructoracr.azurecr.io/todomanagement-api:latest` | API Container App 使用 |
| Web image | `instructoracr.azurecr.io/todomanagement-web:latest` | Web Container App 使用 |
| Registry login server | `instructoracr.azurecr.io` | 选择镜像时需要 |
| Web authentication variable names | 由讲师提供 | 本指南使用 `VITE_AZURE_CLIENT_ID` 和 `VITE_AZURE_AUTHORITY`。`VITE_AZURE_REDIRECT_URI` 可选，默认使用当前 Web App URL。 |

> 讲师说明: 为了简化动手环节，请在课前准备并测试 API 和 Web 两个镜像。ACR remote build 的准备步骤请参阅 [INSTRUCTOR_PREP_GUIDE.md](INSTRUCTOR_PREP_GUIDE.md)。对于此简化 Portal 流程，Web 镜像应从运行时环境变量读取 Microsoft Entra ID 设置，这样学员可以在创建 Container App 时直接输入这些值。

---

## 阶段 2: 从 Azure Portal 创建基础设施

> 预计耗时: 30-40 分钟

从 Azure Portal 创建所有 Azure 资源。您将把已经准备好的镜像直接部署到 Container Apps。

> 注意: 如果 Portal 显示语言是日语或中文，使用英文服务名搜索时，部分服务可能无法命中。请按界面语言使用对应服务名进行搜索。
> 示例: `Resource groups` / `リソース グループ` / `资源组`, `Virtual networks` / `仮想ネットワーク` / `虚拟网络`, `Container Apps` / `コンテナー アプリ` / `容器应用`

### 架构概述

以下图表显示所有组件如何在您的 Azure 环境中部署:

![架构概述 - Azure 上的 Todo Management 应用](../images/01.Architecture.png)

**架构亮点:**

- Web 和 API 容器在 Virtual Network 内的同一 Container Apps Environment 中运行
- API 使用 managed identity 安全访问 PostgreSQL 数据库
- 所有网络流量通过 Virtual Network 内的子网流动
- Microsoft Entra ID 处理用户认证

---

### 资源创建顺序

按以下顺序创建资源，以确保网络配置正确:

1. Resource Group
2. Virtual Network 和子网
3. User-assigned managed identity (用于 API)
4. Azure Database for PostgreSQL Flexible Server
5. Microsoft Entra ID app registration (用于 Web 登录)
6. Azure Container Apps Environment 和 Container Apps

---

### 步骤 2.1: 创建 Resource Group

参考: [Create resource groups - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)

1. 在 Azure Portal 中导航到 **Home** > **Resource groups**
2. 点击 **Create**
3. 在 **Create a resource group** 页面:
   - **Subscription**: 选择您的订阅
   - **Resource group**: 输入名称 (示例: `rg-todomanagement-dev`)
   - **Region**: 选择区域 (示例: `Japan East`)
4. 点击 **Review + Create** -> **Create**
5. 等待部署完成 (通常 1-3 秒)

> 接下来: 记下 Resource Group 名称，后续步骤会用到

---

### 步骤 2.2: 创建 Virtual Network 和子网

参考: [Create a virtual network - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-portal)

Virtual Network 为资源提供隔离的网络空间。请为不同工作负载创建多个子网。

1. 在 Azure Portal 中，进入 **Home** > 搜索 **Virtual networks**
2. 点击 **Create**
3. 在 **Create virtual network** 页面:

   - **Subscription**: 选择您的订阅
   - **Resource group**: 选择步骤 2.1 中的 Resource Group
   - **Name**: 输入名称 (示例: `vnet-todomanagement-dev`)
   - **Region**: 与 Resource Group 相同的区域 (示例: `Japan East`)
4. 点击 **Next**
5. 点击 **Next** 跳过 **Security** 设置
6. 配置 Address Space
   1. 在 **IPv4 address space** 下，设置:
      - **Address space**: `10.0.0.0/16` (提供 65,536 个 IP 地址)

   2. 创建子网

点击 **Add a subnet** 并创建两个子网:

#### 子网 1: Container Apps subnet

- **Name**: `snet-container-apps`
- **Subnet address range**: `10.0.1.0/24` (256 个地址)
- **Private subnet**: 不选择
- **Subnet Delegation**: `Microsoft.App/environments`
- **Other settings**: 保持默认值
- 点击 **Add**

![为 Container App Environment 创建子网](images/add-snet-container-apps.png)

#### 子网 2: PostgreSQL subnet

- **Name**: `snet-postgresql`
- **Subnet address range**: `10.0.2.0/24` (256 个地址)
- **Subnet Delegation**: `Microsoft.DBforPostgreSQL/flexibleServers`
- **Other settings**: 保持默认值
- 点击 **Add**

![为 PostgreSQL 创建子网](image/DEPLOY_GUIDE_GUI/1776060713048.png)
7. 添加两个子网后，点击 **Review + create** -> **Create**
8. 等待 Virtual Network 部署完成 (通常 5-10 秒)

接下来: 记下 VNet 名称和子网名称

> **创建资源时参考您的子网:**
>
> - Container Apps Environment -> `snet-container-apps`
> - PostgreSQL Flexible Server -> `snet-postgresql`

---

### 步骤 2.3: 创建 User-Assigned Managed Identity

参考: [Create a user assigned managed identity - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?tabs=azure-portal)

此 identity 将由 API 容器用于访问 PostgreSQL。

1. 在 Azure Portal 中，进入 **Home** > 搜索 **Managed Identities**
2. 点击 **Create**
3. 在 **Create User Assigned Managed Identity** 页面:
   - **Subscription**: 选择您的订阅
   - **Resource group**: 选择步骤 2.1 中的 Resource Group
   - **Region**: 与 Resource Group 相同
   - **Name**: 输入名称 (示例: `uai-todomanagement-api`)
     ![创建 user assigned identity](image/DEPLOY_GUIDE_GUI/1776067573014.png)
4. 点击 **Review + Create** -> **Create**
5. 等待部署完成 (通常 1-5 秒)
6. 点击新创建的 managed identity 并打开

**接下来: 记下:**

- **Client ID** (Overview 页面)

---

### 步骤 2.4: 创建 Azure Database for PostgreSQL Flexible Server

参考: [Create a server - Azure Database for PostgreSQL Flexible Server (MS Learn)](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal)

1. 在 Azure Portal 中，进入 **Home** > 搜索 **Azure Database for PostgreSQL flexible servers**
2. 点击 **Create**
3. 在 **Create Azure Database for PostgreSQL Flexible Server** 页面:
   - **Subscription**: 选择您的订阅
   - **Resource group**: 选择步骤 2.1 中的 Resource Group
   - **Server name**: 输入名称 (示例: `pg-todomanagement-dev`)
   - **Region**: 与 Resource Group 相同
   - **PostgreSQL version**: 选择 `17`
   - **Workload type**: 选择 `Dev/Test`
   - **Compute + storage**: 开发用途保持默认值
   - **Authentication method**: 选择 `Microsoft Entra authentication only`
   - **Microsoft Entra administrator**: 选择您的用户。
     ![设置 PostgreSQL 基础信息](image/DEPLOY_GUIDE_GUI/1776066601112.png)
4. 点击 **Next: Networking**
5. 在 **Networking** 页面:
   - **Connectivity method**: 选择 `Private access (VNet Integration)` (出于安全考虑推荐)
   - **Virtual network**:
     - **Subscription**: 选择您的订阅
   - **Virtual network**: 选择步骤 2.2 中的 VNet (例如 `vnet-todomanagement-dev`)
   - **Subnet**: 选择 `snet-postgresql` (步骤 2.2)
   - **Private DNS integration**:
     - **Subscription**: 选择您的订阅
     - **Private DNS zone**: 选择 `(New) privatelink.postgres.database.azure.com`。如果已存在同名 private zone，Azure 可能显示类似 `(New) pg-todomanagement-dev.private.postgres.database.azure.com` 的区域。
       ![1776067049715](image/DEPLOY_GUIDE_GUI/1776067049715.png)
6. 点击 **Review + Create** -> **Create**
7. 等待部署完成 (通常 5-10 分钟)

**接下来: 记下:**

- PostgreSQL server endpoint (例如 `pg-todomanagement-dev.postgres.database.azure.com`)

---

### 步骤 2.5: 配置 PostgreSQL 数据库和权限

参考: [Configure server parameters - Azure Database for PostgreSQL (MS Learn)](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-server-parameters)

1. 在 Azure Portal 中，进入步骤 2.4 创建的 PostgreSQL server
2. 在左侧菜单中，点击 **Databases**
3. 点击 **Add**
4. 输入数据库名称: `tododb`
5. 点击 **Save**
6. 等待数据库创建完成 (通常 1-2 分钟)

**授予 Managed Identity 访问 PostgreSQL 数据库的权限:**

1. 在 Azure Portal 中，进入您的 PostgreSQL server
2. 在左侧菜单中，点击 **Security** -> **Authentication**
3. 点击 **Add Microsoft Entra administrators**。在 **Select Microsoft Entra administrators** 对话框中，搜索步骤 2.3 创建的 managed identity (示例: `uai-todomanagement-api`) 并点击 **Select**
   ![1776068408432](image/DEPLOY_GUIDE_GUI/1776068408432.png)
4. 点击 **Save**，等待配置生效

> 注: 最小权限数据库角色设计超出本动手指南范围。有关为 Microsoft Entra principal 创建数据库用户和授予角色的生产指导，请参阅 [Manage Microsoft Entra Users - Azure Database for PostgreSQL | Microsoft Learn](https://learn.microsoft.com/en-us/azure/postgresql/security/security-manage-entra-users)。

---

### 步骤 2.6: 创建 Microsoft Entra ID App Registration

参考: [Register an application - Microsoft Entra ID (MS Learn)](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

在创建 Web Container App 前先创建 app registration，这样可以在创建 Container App 时把 client ID 和 tenant 信息作为环境变量输入。最终 Redirect URI 会在 Web Container App URL 可用后再添加。

1. 在 Azure Portal 中打开 **Microsoft Entra ID** (或搜索)
2. 在左侧菜单中，点击 **App registrations**
3. 点击 **New registration**
4. 在 **Register an application** 页面:
   - **Name**: 输入名称 (示例: `todo-web-app`)
   - **Supported account types**: 选择 **Accounts in this organizational directory only**
   - **Redirect URI**: 暂时留空。Web Container App URL 创建完成后，将在步骤 3.2 中添加。
5. 点击 **Register**
   ![为 Web 认证注册应用](images/register-an-application.png)
6. 应用注册完成。记下:
   - **Application (client) ID** (Overview 页面)
   - **Directory (tenant) ID** (Overview 页面)

---

### 步骤 2.7: 使用讲师镜像创建 API Container App

参考: [Create your first container app with Container Apps - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/container-apps/quickstart-portal)

先创建 API Container App。此步骤也会创建 Container Apps Environment。

> 建议: Container App 名称保持为 `app-todomanagement-api` 和 `app-todomanagement-web`。如果使用其他名称，请同步更新后续步骤中输入的值。

1. 在 Azure Portal 中，进入 **Home** > 搜索 **Container Apps**
2. 点击 **Create** > **Container App**
   ![1776062129864](image/DEPLOY_GUIDE_GUI/1776062129864.png)
3. 在 **Basics** 页面:

   - **Project details**:
     - **Subscription**: 选择您的订阅
     - **Resource group**: 选择步骤 2.1 中的 Resource Group
     - **Container app name**: 输入 `app-todomanagement-api`
     - 其他设置保持默认值
       ![设置 Container App 项目详情](image/DEPLOY_GUIDE_GUI/1776062438077.png)
   - **Container Apps environment**:
     - **Region**: 与 Resource Group 相同
     - 对于 **Container Apps environment**，点击 **Create new environment**
       在 **Create Container Apps environment** 对话框中:
       1. 在 **Basics** 页面:

          - **Environment name**: 输入名称 (示例: `cae-todomanagement-dev`)
          - 其他设置保持默认值
       2. 在 **Monitoring** 页面:

          - **Logs Destination**: 选择 **Azure Log Analytics**
          - **Log Analytics workspace**: 点击 **Create new**
            - **Name**: 输入名称 (示例: `law-todomanagement-dev`)
            - 点击 **OK**

          ![为 Container App 创建 Log Analytics workspace](image/DEPLOY_GUIDE_GUI/1776063748691.png)
       3. 在 **Networking** 页面:

          - **Public Network Access**: 选择 **Enabled**，因为后续步骤需要验证应用
          - **Use your own virtual network**: 选择 `Yes`，然后指定步骤 2.2 中的 virtual network 和 `snet-container-apps` 子网
          - 其他设置保持默认值

          ![设置 Container App 网络](image/DEPLOY_GUIDE_GUI/1776064059196.png)
       4. 点击 **Create**

          ![设置 Container App 基础信息](image/DEPLOY_GUIDE_GUI/1776064144478.png)
4. 点击 **Next: Container**
5. 在 **Container** 页面，输入讲师提供的 API image:

   - **Name**: 输入 `app-todomanagement-api`
   - **Image source**: 选择 `Azure Container Registry`
   - **Image and tag**: 输入讲师提供的 API image 和 tag (示例: `todomanagement-api:workshop-20260707`)
   - 使用 system-assigned managed identity 进行 registry authentication。不要输入 registry username/password。
   - 如果 Portal 要求设置 registry authentication，选择 `Managed identity` 和 `System assigned`。
   - 其他设置保持默认值
![选择容器镜像](image/DEPLOY_GUIDE_GUI/1783410897343.png)

6. 为 API container 添加环境变量:

| Name | Value |
| ---- | ----- |
| `USER_ASSIGNED_IDENTITY_CLIENT_ID` | 步骤 2.3 中的 Managed Identity Client ID |
| `POSTGRES_SERVER` | 步骤 2.4 中的 PostgreSQL server endpoint |
| `POSTGRES_DB` | `tododb` |
| `POSTGRES_USER` | 步骤 2.3 中的 Managed Identity 名称，例如 `uai-todomanagement-api` |
| `DATABASE_TYPE` | `postgresql` |
| `ENVIRONMENT` | `production` |
![设置 API container 环境变量](images/setup-api-container-env-vars.png)

1. 点击 **Next: Ingress**
2. 在 **Ingress** 页面:
   - **Ingress**: 确保已启用
   - **Ingress traffic**: 选择 `Limited to Container Apps Environment`
   - **Target port**: 输入 `8000`
   - 其他设置保持默认值
     ![配置 ingress 设置](images/setup-api-container-ingress.png)
3. 点击 **Review + Create** -> **Create**
4. 等待部署完成 (通常 4-5 分钟)
5. 部署完成后，点击 **Go to resource** 进入创建的应用
6. 在 **Overview** 页面，记下 API app 的 **Application URL** (示例: `https://app-todomanagement-api.internal.politebay-d0fe95ab.japaneast.azurecontainerapps.io`)

继续前，打开 API Container App 的 **Identity**，确认 **System assigned** 为 `On`。使用当前登录的 Azure Portal 账号 (该账号应在讲师 ACR 上具有 Owner 权限)，为这个 **Object (principal) ID** 授予 `AcrPull`。

接下来: 记下 Container Apps Environment 名称和 API app Application URL。

---

### 步骤 2.8: 使用讲师镜像创建 Web Container App

1. 在 Azure Portal 中，进入 **Home** > 搜索 **Container Apps**
2. 点击 **Create** > **Container App**
   ![1776062129864](image/DEPLOY_GUIDE_GUI/1776062129864.png)
3. 在 **Basics** 页面:

   - **Project details**:
     - **Subscription**: 选择您的订阅
     - **Resource group**: 选择步骤 2.1 中的 Resource Group
     - **Container app name**: 输入 `app-todomanagement-web`
     - 其他设置保持默认值
   - **Container Apps environment**:
     - **Region**: 与 Resource Group 相同 (示例: `Japan East`)
   - **Container Apps environment**: 选择步骤 2.7 中创建的 Container Apps Environment (示例: `cae-todomanagement-dev`)
       ![设置 Web Container App 基础信息](image/DEPLOY_GUIDE_GUI/1776065673120.png)
4. 点击 **Next: Container**
5. 在 **Container** 页面，输入讲师提供的 web image:

   - **Name**: 输入 `app-todomanagement-web`
   - **Image source**: 选择 `Azure Container Registry`
   - **Image and tag**: 输入讲师提供的 web image 和 tag (示例: `todomanagement-web:workshop-20260707`)
   - **CPU and memory**: 选择 `0.25 CPU cores, 0.5 Gi memory`
   - 使用 system-assigned managed identity 进行 registry authentication。不要输入 registry username/password。
   - 如果 Portal 要求设置 registry authentication，选择 `Managed identity` 和 `System assigned`。

6. 为 web container 添加以下环境变量:
   `API_PROXY_TARGET` 使用步骤 2.7 中的 internal API URL。

   | Name | Value |
   | ---- | ----- |
   | `API_PROXY_TARGET` | 步骤 2.7 中的 internal API Container App URL |
   | `VITE_AZURE_CLIENT_ID` | 步骤 2.6 中的 Entra ID App Client ID |
   | `VITE_AZURE_AUTHORITY` | 使用步骤 2.6 中的 Entra ID App Tenant ID，格式为 `https://login.microsoftonline.com/<tenant-id>` |

7. 点击 **Next: Ingress**
8. 在 **Ingress** 页面:

   - **Ingress**: 确保已启用
   - **Ingress traffic**: 选择 `Accepting traffic from anywhere`
   - **Target port**: 输入 `80`
   - 其他设置保持默认值
     ![配置 ingress 设置](image/DEPLOY_GUIDE_GUI/1776150754561.png)
9. 点击 **Review + Create** -> **Create**
10. 等待部署完成 (通常 1-2 分钟)
11. 部署完成后，点击 **Go to resource** 进入创建的应用
12. 在 **Overview** 页面，记下 web app 的 **Application URL** (示例: `https://app-todomanagement-web.politebay-d0fe95ab.japaneast.azurecontainerapps.io`)

继续前，打开 Web Container App 的 **Identity**，确认 **System assigned** 为 `On`。使用当前登录的 Azure Portal 账号 (该账号应在讲师 ACR 上具有 Owner 权限)，为这个 **Object (principal) ID** 授予 `AcrPull`。

接下来: 保留 web Application URL，用于阶段 3 验证。

---

## 阶段 3: 验证部署

> 预计耗时: 10 分钟

### 步骤 3.1: 验证 Container App 部署

1. 在 Azure Portal 中，进入您的 **Container Apps Environment**
2. 应该可以看到两个 container app:
   - `app-todomanagement-api`
   - `app-todomanagement-web`
3. 点击 `app-todomanagement-web` 并记下 web app **URL**
4. 点击 `app-todomanagement-api` 并记下 internal API **URL**

---

### 步骤 3.2: 添加 Entra ID Redirect URI

Web Container App URL 可用后，将它添加到 Microsoft Entra ID app registration。

1. 进入您的 **Entra ID App registration** (步骤 2.6)
2. 点击 **Authentication**
3. 在 **Single-page application** 下，添加步骤 3.1 中的 Web Container App URL
4. 使用 `https://<your-web-url>`
   - 将 `<your-web-url>` 替换为步骤 3.1 中的 web app URL
   - 不要附加 `/callback`
5. 点击 **Save**

---

### 步骤 3.3: 测试应用

1. 在浏览器中打开 web application URL
2. 点击 **Login**
3. 使用 Microsoft Entra ID 凭据登录
4. 登录后，应该看到 **Todo List** 页面
5. 测试功能:
   - **Create**: 添加新的 todo item 并点击 Save
   - **Edit**: 点击 todo item 进行编辑
   - **Delete**: 点击 delete 按钮删除 todo item
   - **Refresh**: 刷新页面后，所有更改都应保留

**如果登录失败:**

- 检查 Entra ID redirect URI 是否正确
- 与讲师确认 web image 的 Microsoft Entra ID client ID 和 tenant/authority 配置
- 检查浏览器控制台错误详情 (F12 > Console)

**如果 API 无响应:**

- 检查 PostgreSQL database 是否可访问
- 检查 managed identity 是否拥有数据库权限
- 检查 Container Apps 中的 API container logs

---

## 完成汇总

您的 Todo Management 应用现在已部署到 Azure。

**已部署内容:**

- ✅ 具有 todo schema 的 PostgreSQL database
- ✅ Azure Container Apps 中的 API container
- ✅ Azure Container Apps 中的 Web container
- ✅ 通过 Microsoft Entra ID 的用户认证
- ✅ 在 Azure Container Apps 中运行的讲师提供容器镜像

**后续步骤:**

- 在 Azure Application Insights 中监视应用
- 学习 `DEPLOY_GUIDE.md` 中的 IaC 方法
- 为您的组织定制应用

---

## 常见问题和疑难排解

### 无法拉取容器镜像

**错误**: Container App revision 启动失败，或日志中显示 image pull error。

**解决方案:**

- 确认 image name 和 tag 与讲师提供的值完全一致
- 确认 registry login server 正确
- 确认 Container App system-assigned managed identity 在讲师 ACR 上具有 `AcrPull`
- 在 Container Apps 的 **Revision management** 中检查最新 revision 是否 active 且 healthy

### API 无法连接到 PostgreSQL

**错误**: `could not translate host name "pg-..." to address`

**解决方案:**

- 检查 `POSTGRES_SERVER` 变量与 PostgreSQL server hostname 完全匹配
- 确认 PostgreSQL server 已连接到正确的 VNet、subnet 和 private DNS zone
- 确认 managed identity 具有预期数据库权限
- 确认 `POSTGRES_USER` 设置为 managed identity 名称，而不是 `postgres`

### Web 登录失败或显示错误

**错误**: `AADSTS50058: Silent sign-in request failed`

**解决方案:**

- 与讲师确认 web image 的 Microsoft Entra ID client ID 和 tenant/authority 配置
- 检查您打开的 web URL 是否与 Entra ID 中注册的 redirect URI 完全匹配 (步骤 3.2)
- 确保 Entra ID 中的 redirect URI 使用 `https://` scheme

### Container Apps 未显示部署

**错误**: 在 Container Apps Environment 中看不到 `app-todomanagement-api` 或 `app-todomanagement-web`

**解决方案:**

- 确认两个 Container Apps 都创建在同一个 Container Apps Environment 中
- 检查每个 app 的 **Revision management**，确认最新 revision 为 active
- 确认讲师提供的 image name 和 tag 输入正确
- 确认 `RESOURCE_GROUP` 和 Container App 名称与创建时一致

---

## 后续步骤

- **初学者路径完成:** 应用已可使用!
- **高级路径:** 学习 `DEPLOY_GUIDE.md` 中的 Infrastructure as Code
