# Instructor Preparation Guide

[English](INSTRUCTOR_PREP_GUIDE.md) | [简体中文](INSTRUCTOR_PREP_GUIDE-zh_CN.md) | [日本語](INSTRUCTOR_PREP_GUIDE-ja_JP.md)

This guide is for instructors. Before the workshop, create Azure Container Registry and use ACR remote build from Azure Cloud Shell to build and push the API/Web images. During the hands-on, learners only select the instructor-provided images. They do not need GitHub Actions or local Docker.

---

## Prerequisites

- Instructor has access to an Azure subscription
- Instructor can run `az` commands in Azure Cloud Shell
- Instructor has prepared this repository source code
- Instructor has permission to create a Resource Group and Azure Container Registry

> Note: This guide uses `az acr build`. The build runs remotely in ACR and does not require Docker installed in Cloud Shell.

---

## 1. Prepare Source Code in Cloud Shell

Open **Cloud Shell** from the upper-right corner of Azure Portal and select **Bash**.

If the repository is in GitHub:

```bash
git clone <repository-url>
cd todomanagement
```

If the source code is a zip file:

```bash
unzip todomanagement.zip
cd todomanagement
```

Confirm the directory structure:

```bash
ls src/api/Dockerfile src/web/Dockerfile
```

---

## 2. Set Variables

Update these values for your workshop environment:

```bash
SUBSCRIPTION_ID="<subscription-id>"
LOCATION="japaneast"
RESOURCE_GROUP="rg-todomanagement-instructor"
ACR_NAME="<globally-unique-acr-name>"
IMAGE_TAG="workshop-$(date +%Y%m%d)"
API_IMAGE="todomanagement-api:${IMAGE_TAG}"
WEB_IMAGE="todomanagement-web:${IMAGE_TAG}"
```

Requirements:

- `ACR_NAME` must be globally unique
- Use only lowercase letters and numbers
- Length must be 5 to 50 characters
- Do not use `-` or `_`

Check whether the ACR name is available:

```bash
az acr check-name --name "$ACR_NAME"
```

Select the subscription:

```bash
az account set --subscription "$SUBSCRIPTION_ID"
```

---

## 3. Create Resource Group and ACR

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic
```

To simplify learner operations in the workshop, you can temporarily enable the ACR admin user. Learners can then enter registry username/password on the Container Apps creation page.

```bash
az acr update \
  --name "$ACR_NAME" \
  --admin-enabled true
```

> After the workshop, disable the admin user or rotate the password. For production, prefer managed identity for image pull.

---

## 4. Remote Build API Image

Run from the repository root:

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$API_IMAGE" \
  --file src/api/Dockerfile \
  src/api
```

Notes:

- `src/api` is the build context
- Local Docker is not required
- ACR remote build automatically pushes the image to the current ACR

---

## 5. Remote Build Web Image

Run from the repository root:

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$WEB_IMAGE" \
  --file src/web/Dockerfile \
  src/web
```

Notes:

- `src/web` is the build context
- The Web image does not need `VITE_AZURE_CLIENT_ID`, `VITE_AZURE_AUTHORITY`, or `VITE_AZURE_REDIRECT_URI` at build time
- Learners set the client ID and authority as environment variables when creating the Web Container App. The redirect URI defaults to the current web app URL.

---

## 6. Verify Images

List repositories:

```bash
az acr repository list \
  --name "$ACR_NAME" \
  --output table
```

Show API tags:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-api \
  --output table
```

Show Web tags:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-web \
  --output table
```

Get the login server:

```bash
LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --query loginServer \
  --output tsv)

echo "$LOGIN_SERVER"
```

Print full image names:

```bash
echo "API image: ${LOGIN_SERVER}/${API_IMAGE}"
echo "Web image: ${LOGIN_SERVER}/${WEB_IMAGE}"
```

---

## 7. Get Information for Learners

If you use the ACR admin user:

```bash
ACR_USERNAME=$(az acr credential show \
  --name "$ACR_NAME" \
  --query username \
  --output tsv)

ACR_PASSWORD=$(az acr credential show \
  --name "$ACR_NAME" \
  --query passwords[0].value \
  --output tsv)

echo "Registry login server: ${LOGIN_SERVER}"
echo "Registry username: ${ACR_USERNAME}"
echo "Registry password: ${ACR_PASSWORD}"
echo "API image: ${LOGIN_SERVER}/${API_IMAGE}"
echo "Web image: ${LOGIN_SERVER}/${WEB_IMAGE}"
```

Share this information with learners:

| Item | Value |
| ---- | ----- |
| Registry login server | `${LOGIN_SERVER}` |
| Registry username | `${ACR_USERNAME}` |
| Registry password | `${ACR_PASSWORD}` |
| API image | `${LOGIN_SERVER}/${API_IMAGE}` |
| Web image | `${LOGIN_SERVER}/${WEB_IMAGE}` |

---

## 8. Web Container App Environment Variables for Learners

The Web image supports runtime configuration. Learners set these values when creating the Web Container App:

| Name | Example |
| ---- | ------- |
| `API_PROXY_TARGET` | `https://app-todomanagement-api.internal.<environment-domain>.azurecontainerapps.io` |
| `VITE_AZURE_CLIENT_ID` | Microsoft Entra ID app registration client ID |
| `VITE_AZURE_AUTHORITY` | `https://login.microsoftonline.com/<tenant-id>` |

`VITE_AZURE_REDIRECT_URI` is optional. If it is not set, the web app uses the current browser address as the redirect URI.

The API image does not need environment variables baked in at build time. Learners set database and managed identity variables while creating the API Container App, following the hands-on guide.

---

## 9. Pre-Workshop Checklist

- ACR has been created
- ACR admin user has been enabled, or another image pull authentication method is ready
- API image remote build succeeded
- Web image remote build succeeded
- `todomanagement-api` and `todomanagement-web` tags can be queried
- Registry login server has been recorded
- Registry username/password have been recorded
- Full API/Web image names have been shared with learners
- Web image does not depend on build-time `VITE_AZURE_*` parameters

---

## Troubleshooting

### ACR Name Is Not Available

Use another globally unique name with only lowercase letters and numbers.

```bash
az acr check-name --name "<new-acr-name>"
```

### `az acr build` Cannot Find Dockerfile

Confirm that the current directory is the repository root:

```bash
pwd
ls src/api/Dockerfile src/web/Dockerfile
```

### Web Sign-In Configuration Does Not Take Effect

Confirm that learners set these environment variables on the Web Container App and created a new revision:

- `VITE_AZURE_CLIENT_ID`
- `VITE_AZURE_AUTHORITY`

Also confirm that the web URL they opened is registered as a redirect URI in the Microsoft Entra ID app registration.

### Learners Cannot Pull Images

Confirm:

- Container App registry login server is correct
- username/password are correct
- ACR admin user is enabled
- image name includes the full registry prefix, for example `myacr.azurecr.io/todomanagement-web:workshop-20260706`
