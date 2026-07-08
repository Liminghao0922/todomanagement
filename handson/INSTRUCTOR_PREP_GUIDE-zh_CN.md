# 讲师准备指南

[English](INSTRUCTOR_PREP_GUIDE.md) | [简体中文](INSTRUCTOR_PREP_GUIDE-zh_CN.md) | [日本語](INSTRUCTOR_PREP_GUIDE-ja_JP.md)

本文件给讲师使用。目标是在课前创建 Azure Container Registry，并用 Azure Cloud Shell 的 ACR remote build 预先构建、推送 API/Web 镜像。学员 hands-on 时只需要选择讲师提供的镜像，不需要 GitHub Actions，也不需要本地 Docker。

---

## 前提条件

- 讲师有可用 Azure subscription
- 讲师能在 Azure Cloud Shell 中运行 `az` 命令
- 讲师已准备好本仓库源码
- 讲师有权限创建 Resource Group 和 Azure Container Registry

> 注意：本步骤使用 `az acr build`。构建发生在 ACR 远端，不依赖 Cloud Shell 中安装 Docker。

---

## 1. 在 Cloud Shell 准备源码

打开 Azure Portal 右上角 **Cloud Shell**，选择 **Bash**。

如果仓库在 GitHub：

```bash
git clone <repository-url>
cd todomanagement
```

如果源码是 zip 包：

```bash
unzip todomanagement.zip
cd todomanagement
```

确认目录结构：

```bash
ls src/api/Dockerfile src/web/Dockerfile
```

---

## 2. 设置变量

按实际课堂环境修改这些值：

```bash
SUBSCRIPTION_ID="<subscription-id>"
LOCATION="japaneast"
RESOURCE_GROUP="rg-todomanagement-instructor"
ACR_NAME="<globally-unique-acr-name>"
IMAGE_TAG="workshop-$(date +%Y%m%d)"
API_IMAGE="todomanagement-api:${IMAGE_TAG}"
WEB_IMAGE="todomanagement-web:${IMAGE_TAG}"
```

要求：

- `ACR_NAME` 必须全局唯一
- 只能使用小写字母和数字
- 长度 5 到 50
- 不能包含 `-` 或 `_`

检查 ACR 名称是否可用：

```bash
az acr check-name --name "$ACR_NAME"
```

选择 subscription：

```bash
az account set --subscription "$SUBSCRIPTION_ID"
```

---

## 3. 创建 Resource Group 和 ACR

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic
```

保持 ACR admin user 关闭。本 workshop 中，Container Apps 应该使用自己的 system-assigned managed identity 从 ACR 拉取镜像。

```bash
az acr show \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "{loginServer:loginServer, adminUserEnabled:adminUserEnabled}" \
  --output table
```

> 课前需要给每个学员账号授予讲师 ACR 上的 Owner 角色。这是为了 workshop 快速落地，让学员可以在 Azure Portal 中自行创建所需的 `AcrPull` role assignment，而不需要讲师逐个介入。Container App 的运行时 identity 仍然只需要 `AcrPull`。生产环境建议遵循最小权限原则：不要给应用使用者广泛的 Owner 权限，应由平台负责人或自动化流程只给指定的 Container App managed identity 授予 `AcrPull`。

---

## 4. Remote build API image

从仓库根目录运行：

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$API_IMAGE" \
  --file src/api/Dockerfile \
  src/api
```

说明：

- `src/api` 是 build context
- 不需要本地 Docker
- ACR remote build 会自动把镜像推送到当前 ACR

---

## 5. Remote build Web image

从仓库根目录运行：

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$WEB_IMAGE" \
  --file src/web/Dockerfile \
  src/web
```

说明：

- `src/web` 是 build context
- Web image 不需要在 build 时传入 `VITE_AZURE_CLIENT_ID`、`VITE_AZURE_AUTHORITY`、`VITE_AZURE_REDIRECT_URI`
- 学员创建 Web Container App 时只需要设置 client ID 和 authority。Redirect URI 默认使用当前 Web app URL。

---

## 6. 验证镜像

查看仓库：

```bash
az acr repository list \
  --name "$ACR_NAME" \
  --output table
```

查看 API tags：

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-api \
  --output table
```

查看 Web tags：

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-web \
  --output table
```

取得 login server：

```bash
LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --query loginServer \
  --output tsv)

echo "$LOGIN_SERVER"
```

完整镜像名称：

```bash
echo "API image: ${LOGIN_SERVER}/${API_IMAGE}"
echo "Web image: ${LOGIN_SERVER}/${WEB_IMAGE}"
```

---

## 7. 取得提供给学员的信息

把以下信息发给学员：

| Item | Value |
| ---- | ----- |
| Registry login server | `${LOGIN_SERVER}` |
| API image | `${LOGIN_SERVER}/${API_IMAGE}` |
| Web image | `${LOGIN_SERVER}/${WEB_IMAGE}` |

---

## 8. 学员需要设置的 Web Container App 环境变量

Web image 已支持运行时配置。学员创建 Web Container App 时设置：

| Name | Example |
| ---- | ------- |
| `API_PROXY_TARGET` | `https://app-todomanagement-api.internal.<environment-domain>.azurecontainerapps.io` |
| `VITE_AZURE_CLIENT_ID` | Microsoft Entra ID app registration client ID |
| `VITE_AZURE_AUTHORITY` | `https://login.microsoftonline.com/<tenant-id>` |

`VITE_AZURE_REDIRECT_URI` 是可选项。不设置时，Web app 会使用当前浏览器访问地址作为 redirect URI。

API image 不需要在 build 时写入环境变量。学员创建 API Container App 时按 hands-on guide 设置数据库、managed identity 相关变量。

---

## 9. 课前检查清单

- ACR 已创建
- ACR admin user 保持关闭
- API image 已 remote build 成功
- Web image 已 remote build 成功
- `todomanagement-api` 和 `todomanagement-web` tags 可查询
- 已记录 registry login server
- 已把完整 API/Web image 名称发给学员
- 学员账号已在讲师 ACR 上获得 Owner 角色

---

## 常见问题

### ACR 名称不可用

换一个全局唯一名称，只用小写字母和数字。

```bash
az acr check-name --name "<new-acr-name>"
```

### `az acr build` 找不到 Dockerfile

确认当前目录是仓库根目录：

```bash
pwd
ls src/api/Dockerfile src/web/Dockerfile
```

### Web 登录配置不生效

确认学员在 Web Container App 上设置了这些环境变量，并创建了新 revision：

- `VITE_AZURE_CLIENT_ID`
- `VITE_AZURE_AUTHORITY`

同时确认学员当前打开的 Web URL 已添加到 Microsoft Entra ID app registration 的 redirect URI。

### 学员无法拉取镜像

确认：

- Container App registry login server 正确
- Container App 已启用 system-assigned managed identity
- Container App identity 已在讲师 ACR 上获得 `AcrPull` 角色
- image 名称包含完整 registry 前缀，例如 `myacr.azurecr.io/todomanagement-web:workshop-20260706`
