# Todo Management GUI Deployment Guide

[English](DEPLOY_GUIDE_GUI.md) | [简体中文](DEPLOY_GUIDE_GUI-zh_CN.md) | [日本語](DEPLOY_GUIDE_GUI-ja_JP.md)

This guide explains the beginner-friendly, Azure Portal-based (GUI-first) deployment path. Use it for workshops or for your first deployment.

Estimated time: 45 to 60 minutes.

---

## Terminology Standard (EN/JA/ZH)

Use the following terms consistently across all language versions:

- Microsoft Entra ID
- Azure Container Apps Environment
- Instructor-provided container image

Notes:

- In the API Container App environment variables, `USER_ASSIGNED_IDENTITY_CLIENT_ID` means the user-assigned managed identity client ID used for PostgreSQL authentication.
- For web sign-in, use the Microsoft Entra ID application client ID and tenant/authority values provided by the instructor or created in this guide.

---

## Workflow Overview

This guide follows these phases:

1. **Phase 1: Preparation** - Confirm the container images and values provided by the instructor
2. **Phase 2: Azure Infrastructure Setup** (via Portal) - Create the required Azure resources and deploy the prepared images
3. **Phase 3: Validation** - Add the redirect URI and test the deployed application

For the IaC/Bicep path, see `DEPLOY_GUIDE.md` (advanced track).

---

## Prerequisites

- Azure subscription permissions: `Owner`
- Owner role on the instructor ACR, so your signed-in Azure Portal account can grant `AcrPull` to the Container App system-assigned identity
- Microsoft Entra ID permission to create app registrations:
  - `Application Administrator`, `Cloud Application Administrator`, or `Application Developer` role
  - If your organization allows all users to register applications (default setting), no special role is required
  - Reference: [Least privileged roles by task - Microsoft Entra ID (MS Learn)](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-by-task)

Collect the following container image information from the instructor:

- API image name and tag
- Web image name and tag
- Registry login server

Important for workshop users:

- Prepare names, region, and required IDs before you start
- This beginner guide does not require GitHub Actions, repository variables, or building container images during the workshop
- The instructor must prepare images that are compatible with the classroom configuration. In particular, the simplified web image must support Microsoft Entra ID configuration through Container App environment variables.

---

## Phase 1: Preparation

> Estimated time: 5 minutes

Before creating Azure resources, collect the image and configuration values from the instructor.

| Item | Example | Notes |
| ---- | ------- | ----- |
| API image | `instructoracr.azurecr.io/todomanagement-api:latest` | Used by the API Container App |
| Web image | `instructoracr.azurecr.io/todomanagement-web:latest` | Used by the web Container App |
| Registry login server | `instructoracr.azurecr.io` | Required when selecting the image |
| Web authentication variable names | Provided by instructor | This guide uses `VITE_AZURE_CLIENT_ID` and `VITE_AZURE_AUTHORITY`. `VITE_AZURE_REDIRECT_URI` is optional and defaults to the current web app URL. |

> Instructor note: To keep the hands-on simple, prepare and test both images before the workshop. For the ACR remote build preparation steps, see [INSTRUCTOR_PREP_GUIDE.md](INSTRUCTOR_PREP_GUIDE.md). For this simplified Portal flow, the web image should read Microsoft Entra ID settings from runtime environment variables so learners can enter those values while creating the Container App.

---

## Phase 2: Create Infrastructure from Azure Portal

> Estimated time: 30-40 minutes

Create all Azure resources from Azure Portal. You will deploy the prepared images directly into Container Apps.

> Note: If your Portal display language is Japanese or Chinese, some services may not appear when searched by English names. In that case, search using the localized service name shown in your UI.
> Examples: `Resource groups` / `リソース グループ` / `资源组`, `Virtual networks` / `仮想ネットワーク` / `虚拟网络`, `Container Apps` / `コンテナー アプリ` / `容器应用`

### Architecture Overview

The following diagram shows how all components are deployed in your Azure environment:

![Architecture Overview - Todo Management Application on Azure](../images/01.Architecture.png)

**Architecture highlights:**

- User accesses the web application through Container Apps
- Web and API containers run in the same Container Apps Environment within a Virtual Network
- API uses managed identity to securely access PostgreSQL database
- Instructor-provided container images are deployed directly to Container Apps
- All network traffic flows through subnets within the Virtual Network
- Microsoft Entra ID handles user authentication

---

### Resource Creation Order

Create resources in this sequence to ensure proper network configuration:

1. Resource Group
2. Virtual Network and Subnets
3. User-assigned managed identity (for API)
4. Azure Database for PostgreSQL Flexible Server
5. Microsoft Entra ID app registration (for web sign-in)
6. Azure Container Apps Environment and Container Apps

---

### Step 2.1: Create Resource Group

Reference: [Create resource groups - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)

1. Navigate to **Home** > **Resource groups** in Azure Portal
2. Click **Create**
3. On the **Create a resource group** page:
   - **Subscription**: Select your subscription
   - **Resource group**: Enter a name (example: `rg-todomanagement-dev`)
   - **Region**: Select a region (example: `Japan East`)
4. Click **Review + Create** -> **Create**
5. Wait for deployment to complete (usually 1-3 seconds)

> Next: Note down your Resource Group name for later steps

---

### Step 2.2: Create Virtual Network and Subnets

Reference: [Create a virtual network - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-portal)

A Virtual Network provides isolated network space for your resources. Create multiple subnets for different workload types.

1. In Azure Portal, go to **Home** > search for **Virtual networks**
2. Click **Create**
3. On the **Create virtual network** page:

   - **Subscription**: Select your subscription
   - **Resource group**: Select the resource group from Step 2.1
   - **Name**: Enter a name (example: `vnet-todomanagement-dev`)
   - **Region**: Same as resource group (example: `Japan East`)
4. Click **Next**
5. Click **Next** to skip **Security** settings
6. Configure Address Space
   1. Under **IPv4 address space**, set:
      - **Address space**: `10.0.0.0/16` (provides 65,536 IP addresses)

   2. Create Subnets

Click **Add a subnet** and create two subnets:

#### Subnet 1: Container Apps subnet

- **Name**: `snet-container-apps`
- **Subnet address range**: `10.0.1.0/24` (256 addresses)
- **Private subnet**: Unselected
- **Subnet Delegation**: `Microsoft.App/environments`
- **Other settings**: Leave the defaults
- Click **Add**

![Create subnet for container app environment](images/add-snet-container-apps.png)

#### Subnet 2: PostgreSQL subnet

- **Name**: `snet-postgresql`
- **Subnet address range**: `10.0.2.0/24` (256 addresses)
- **Subnet Delegation**: `Microsoft.DBforPostgreSQL/flexibleServers`
- **Other settings**: Leave the defaults
- Click **Add**

![Create subnet for PostgreSQL](image/DEPLOY_GUIDE_GUI/1776060713048.png)
7. After adding both subnets, click **Review + create** -> **Create**
8. Wait for Virtual Network deployment (usually 5-10 seconds)

Next: Note down your VNet name and subnet names
> **Reference your subnets when creating resources:**
> - Container Apps Environment → `snet-container-apps`
> - PostgreSQL Flexible Server → `snet-postgresql`

---

### Step 2.3: Create User-Assigned Managed Identity

Reference: [Create a user assigned managed identity - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?tabs=azure-portal)

This identity will be used by the API container to access PostgreSQL.

1. In Azure Portal, go to **Home** > search for **Managed Identities**
2. Click **Create**
3. On the **Create User Assigned Managed Identity** page:
   - **Subscription**: Select your subscription
   - **Resource group**: Select the resource group from Step 2.1
   - **Region**: Same as resource group
   - **Name**: Enter a name (example: `uai-todomanagement-api`)
     ![Create user assigned identity](image/DEPLOY_GUIDE_GUI/1776067573014.png)
4. Click **Review + Create** -> **Create**
5. Wait for deployment (usually 1-5 seconds)
6. Click on the newly created managed identity to open it

**Next: Note down:**

- **Client ID** (under Overview)

---

### Step 2.4: Create Azure Database for PostgreSQL Flexible Server

Reference: [Create a server - Azure Database for PostgreSQL Flexible Server (MS Learn)](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal)

1. In Azure Portal, go to **Home** > search for **Azure Database for PostgreSQL flexible servers**
2. Click **Create**
3. On the **Create Azure Database for PostgreSQL Flexible Server** page:
   - **Subscription**: Select your subscription
   - **Resource group**: Select the resource group from Step 2.1
   - **Server name**: Enter a name (example: `pg-todomanagement-dev`)
   - **Region**: Same as resource group
   - **PostgreSQL version**: Select `17`
   - **Workload type**: Select `Dev/Test`
   - **Compute + storage**: Keep default for development
   - **Authentication method**: Select `Microsoft Entra authentication only`
   - **Microsoft Entra administrator**: Select your user.
     ![Setup basics for PostgresSQL](image/DEPLOY_GUIDE_GUI/1776066601112.png)
4. Click **Next: Networking**
5. On the **Networking** page:
   - **Connectivity method**: Select `Private access (VNet Integration)` (recommended for security)
   - **Virtual network**:
     - **Subscription**: Select your subscription
   - **Virtual network**: Select VNet from Step 2.2 (e.g., `vnet-todomanagement-dev`)
   - **Subnet**: Select `snet-postgresql` (from Step 2.2)
   - **Private DNS integration**:
     - **Subscription**: Select your subscription
     - **Private DNS zone**: Select `(New) privatelink.postgres.database.azure.com`. If you already have a private zone with the same name, Azure may show a zone such as `(New) pg-todomanagement-dev.private.postgres.database.azure.com`.
       ![1776067049715](image/DEPLOY_GUIDE_GUI/1776067049715.png)
6. Click **Review + Create** -> **Create**
7. Wait for deployment (usually 5-10 minutes)

**Next: Note down:**

- PostgreSQL server endpoint (e.g., `pg-todomanagement-dev.postgres.database.azure.com`)

---

### Step 2.5: Configure PostgreSQL Database and Permissions

Reference: [Configure server parameters - Azure Database for PostgreSQL (MS Learn)](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-server-parameters)

1. In Azure Portal, go to your PostgreSQL server (from Step 2.4)
2. In the left menu, click **Databases**
3. Click **Add**
4. Enter database name: `tododb`
5. Click **Save**
6. Wait for database creation (usually 1-2 minutes)

**Grant Managed Identity Access to PostgreSQL Database:**

1. In Azure Portal, go to your PostgreSQL server
2. In the left menu, click **Security** -> **Authentication**
3. Click **Add Microsoft Entra administrators**. In the **Select Microsoft Entra administrators** dialog, search for the managed identity created in Step 2.3 (example: `uai-todomanagement-api`) and click **Select**
   ![1776068408432](image/DEPLOY_GUIDE_GUI/1776068408432.png)
4. Click **Save**, and wait for configuration to apply

> Note: Least-privilege database role design is outside the scope of this hands-on guide. For production guidance on creating database users and granting roles to Microsoft Entra principals, see [Manage Microsoft Entra Users - Azure Database for PostgreSQL | Microsoft Learn](https://learn.microsoft.com/en-us/azure/postgresql/security/security-manage-entra-users).

---

### Step 2.6: Create Microsoft Entra ID App Registration

Reference: [Register an application - Microsoft Entra ID (MS Learn)](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

Create the app registration before creating the web Container App so you can enter the client ID and tenant information as Container App environment variables. You will add the final redirect URI after the web Container App URL is available.

1. Open **Microsoft Entra ID** in Azure Portal (or search for it)
2. In the left menu, click **App registrations**
3. Click **New registration**
4. On the **Register an application** page:
   - **Name**: Enter a name (example: `todo-web-app`)
   - **Supported account types**: Select **Accounts in this organizational directory only**
   - **Redirect URI**: Leave this blank for now. You will add it in Step 3.2 after the web Container App URL is created.
5. Click **Register**
   ![Register app for the web authentication](images/register-an-application.png)
6. The app is now registered. Note down:
   - **Application (client) ID** (Overview page)
   - **Directory (tenant) ID** (Overview page)

---

### Step 2.7: Create the API Container App from the Instructor Image

Reference: [Create your first container app with Container Apps - Azure Portal (MS Learn)](https://learn.microsoft.com/en-us/azure/container-apps/quickstart-portal)

Create the API Container App first. This step also creates the Container Apps Environment.

> Recommendation: Keep the Container App names as `app-todomanagement-api` and `app-todomanagement-web`. If you use different names, also update the values you enter in later steps.

1. In Azure Portal, go to **Home** > search for **Container Apps**
2. Click **Create** > **Container App**
   ![1776062129864](image/DEPLOY_GUIDE_GUI/1776062129864.png)
3. On the **Basics** page:

   - **Project details**:
     - **Subscription**: Select your subscription
     - **Resource group**: Select the resource group from Step 2.1
     - **Container app name**: Enter `app-todomanagement-api`
     - Leave other settings as default
       ![Setup Container App project details](image/DEPLOY_GUIDE_GUI/1776062438077.png)
   - **Container Apps environment**:
     - **Region**: Same as resource group
     - For **Container Apps environment**, click **Create new environment**
       On the **Create Container Apps environment** dialog:
       1. On the **Basics** page:

          - **Environment name**: Enter a name (example: `cae-todomanagement-dev`)
          - Leave other settings as default
       2. On the **Monitoring** page:

          - **Logs Destination**: choose **Azure Log Analytics**
          - **Log Analytics workspace**: click **Create new**
            - **Name**: Enter a name (example: `law-todomanagement-dev`)
            - Click **OK**

          ![Create Log Analytics workspace for container app](image/DEPLOY_GUIDE_GUI/1776063748691.png)
       3. On the **Networking** page:

          - **Public Network Access**: select **Enabled** because you will validate the application in later steps
          - **Use your own virtual network**: select `Yes`, then specify the virtual network and `snet-container-apps` subnet from Step 2.2
          - Leave other settings as default

          ![Setup networking for container app](image/DEPLOY_GUIDE_GUI/1776064059196.png)
       4. Click **Create**

          ![Setup basics for container app](image/DEPLOY_GUIDE_GUI/1776064144478.png)
4. Click **Next: Container**
5. On the **Container** page, enter the instructor-provided API image:

   - **Name**: Enter `app-todomanagement-api`
   - **Image source**: select `Azure Container Registry`
   - **Image and tag**: enter the instructor-provided API image and tag (example: `todomanagement-api:workshop-20260707`)
   - Use system-assigned managed identity for registry authentication. Do not enter registry username/password.
   - If the Portal asks for registry authentication, select `Managed identity` and `System assigned`.
   - Leave other settings as default
![Select container image](image/DEPLOY_GUIDE_GUI/1783410897343.png)

6. Add environment variables for the API container:

| Name | Value |
| ---- | ----- |
| `USER_ASSIGNED_IDENTITY_CLIENT_ID` | Managed Identity Client ID from Step 2.3 |
| `POSTGRES_SERVER` | PostgreSQL server endpoint from Step 2.4 |
| `POSTGRES_DB` | `tododb` |
| `POSTGRES_USER` | Managed Identity name from Step 2.3, for example `uai-todomanagement-api` |
| `DATABASE_TYPE` | `postgresql` |
| `ENVIRONMENT` | `production` |
![Select api container env vars](images/setup-api-container-env-vars.png)

1. Click **Next: Ingress**
2. On the **Ingress** page:
   - **Ingress**: make sure it is enabled
   - **Ingress traffic**: select `Limited to Container Apps Environment`
   - **Target port**: enter `8000`
   - Leave other settings as default
     ![Config ingress settings](images/setup-api-container-ingress.png)
3. Click **Review + Create** -> **Create**
4.  Wait for deployment (usually 4-5 minutes)
5.  After the deployment is complete, click **Go to resource** to navigate to the created app.
6.  On the **Overview** page, note down the **Application URL** for the API app (example: `https://app-todomanagement-api.internal.politebay-d0fe95ab.japaneast.azurecontainerapps.io`)

Before continuing, open **Identity** for the API Container App and confirm **System assigned** is `On`. Use the currently signed-in Azure Portal account, which should have Owner on the instructor ACR, to assign `AcrPull` to this **Object (principal) ID**.

Next: Note down your Container Apps Environment name and the API app Application URL.

---

### Step 2.8: Create the Web Container App from the Instructor Image

1. In Azure Portal, go to **Home** > search for **Container Apps**
2. Click **Create** > **Container App**
   ![1776062129864](image/DEPLOY_GUIDE_GUI/1776062129864.png)
3. On the **Basics** page:

   - **Project details**:
     - **Subscription**: Select your subscription
     - **Resource group**: Select the resource group from Step 2.1
     - **Container app name**: Enter `app-todomanagement-web`
     - Leave other settings as default
   - **Container Apps environment**:
     - **Region**: Same as resource group (example: `Japan East`)
   - **Container Apps environment**: select the Container Apps environment created in Step 2.7 (example: `cae-todomanagement-dev`)
       ![Setup basics for web container app](image/DEPLOY_GUIDE_GUI/1776065673120.png)
4. Click **Next: Container**
5. On the **Container** page, enter the instructor-provided web image:

   - **Name**: Enter `app-todomanagement-web`
   - **Image source**: select `Azure Container Registry`
   - **Image and tag**: enter the instructor-provided web image and tag (example: `todomanagement-web:workshop-20260707`)
   - **CPU and memory**: select `0.25 CPU cores, 0.5 Gi memory`
   - Use system-assigned managed identity for registry authentication. Do not enter registry username/password.
   - If the Portal asks for registry authentication, select `Managed identity` and `System assigned`.

6. Add these environment variables for the web container:
   Use the internal API URL from Step 2.7 for `API_PROXY_TARGET`.

   | Name | Value |
   | ---- | ----- |
   | `API_PROXY_TARGET` | Internal API Container App URL from Step 2.7 |
   | `VITE_AZURE_CLIENT_ID` | Entra ID App Client ID from Step 2.6 |
   | `VITE_AZURE_AUTHORITY` | `https://login.microsoftonline.com/<tenant-id>` using the Entra ID App Tenant ID from Step 2.6 |

7. Click **Next: Ingress**
8. On the **Ingress** page:

   - **Ingress**: make sure it is enabled
   - **Ingress traffic**: select `Accepting traffic from anywhere`
   - **Target port**: enter `80`
   - Leave other settings as default
     ![Config ingress settings](image/DEPLOY_GUIDE_GUI/1776150754561.png)
9. Click **Review + Create** -> **Create**
10.  Wait for deployment (usually 1-2 minutes)
11.  After the deployment is complete, click **Go to resource** to navigate to the created app.
12.  On the **Overview** page, note down the **Application URL** for the web app (example: `https://app-todomanagement-web.politebay-d0fe95ab.japaneast.azurecontainerapps.io`)

Before continuing, open **Identity** for the Web Container App and confirm **System assigned** is `On`. Use the currently signed-in Azure Portal account, which should have Owner on the instructor ACR, to assign `AcrPull` to this **Object (principal) ID**.

Next: Keep the web Application URL for Phase 3 validation.

---

## Phase 3: Validate Deployment

> Estimated time: 10 minutes

### Step 3.1: Verify Container App Deployments

1. In Azure Portal, go to your **Container Apps Environment**
2. You should see two container apps:
   - `app-todomanagement-api`
   - `app-todomanagement-web`
3. Click `app-todomanagement-web` and note down the web app **URL**
4. Click `app-todomanagement-api` and note down the internal API **URL**

---

### Step 3.2: Add the Entra ID Redirect URI

Now that the web Container App URL is available, add it to the Microsoft Entra ID app registration.

1. Go to your **Entra ID App registration** (from Step 2.6)
2. Click **Authentication**
3. Under **Single-page application**, add the web Container App URL from Step 3.1
4. Use `https://<your-web-url>`
   - Replace `<your-web-url>` with the web app URL from Step 3.1
   - Do not append `/callback`
5. Click **Save**

---

### Step 3.3: Test the Application

1. Open the web application URL in your browser
2. Click **Login**
3. Sign in with your Microsoft Entra ID credentials
4. Once logged in, you should see a **Todo List** page
5. Test the functionality:
   - **Create**: Add a new todo item, click Save
   - **Edit**: Click on a todo item to edit it
   - **Delete**: Click the delete button to remove a todo item
   - **Refresh**: All changes should persist after page refresh

**If login fails:**

- Check Entra ID redirect URI is correct
- Check the web image's Microsoft Entra ID client ID and tenant/authority configuration with the instructor
- Check browser console for error details (F12 > Console)

**If API fails to respond:**

- Check PostgreSQL database is accessible
- Check managed identity has database permissions
- Check API container logs in Container Apps

---

## Summary of Completion

Your Todo Management application is now deployed on Azure.

**What was deployed:**

- ✅ PostgreSQL database with todo schema
- ✅ API container in Azure Container Apps
- ✅ Web container in Azure Container Apps
- ✅ User authentication via Microsoft Entra ID
- ✅ Instructor-provided container images running in Azure Container Apps

**Next steps:**

- Monitor application in Azure Application Insights
- Learn the IaC approach in `DEPLOY_GUIDE.md`
- Customize the application for your organization

---

## Common Issues and Troubleshooting

### Container image cannot be pulled

**Error**: Container App revision fails to start, or the log shows an image pull error.

**Solution:**

- Verify the image name and tag match the values provided by the instructor
- Verify the registry login server is correct
- Verify the Container App system-assigned managed identity has `AcrPull` on the instructor ACR
- Check **Revision management** in Container Apps to see whether the latest revision is active and healthy

### API cannot connect to PostgreSQL

**Error**: `could not translate host name "pg-..." to address`

**Solution:**

- Check `POSTGRES_SERVER` variable matches your PostgreSQL server hostname exactly
- Verify the PostgreSQL server is connected to the correct VNet, subnet, and private DNS zone
- Verify the managed identity has the expected database permissions
- Check that `POSTGRES_USER` is set to the managed identity name, not `postgres`

### Web login fails or shows error

**Error**: `AADSTS50058: Silent sign-in request failed`

**Solution:**

- Verify the web image's Microsoft Entra ID client ID and tenant/authority configuration with the instructor
- Check the web URL you opened matches the exact redirect URI registered in Entra ID (Step 3.2)
- Ensure redirect URI in Entra ID has `https://` scheme

### Container Apps shows no deployments

**Error**: You don't see `app-todomanagement-api` or `app-todomanagement-web` in the Container Apps Environment

**Solution:**

- Confirm both Container Apps were created in the same Container Apps Environment
- Check **Revision management** for each app and confirm the latest revision is active
- Verify the instructor-provided image name and tag were entered correctly
- Verify `RESOURCE_GROUP` and Container App names match what you created

---

## Next Steps

- **Beginner path complete:** Your application is ready to use!
- **Advanced path:** Learn Infrastructure as Code in `DEPLOY_GUIDE.md`
