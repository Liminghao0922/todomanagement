# Complete Deployment Checklist

This checklist guides you through deploying all three enhancements:
1. **ACR Private Endpoint** - Secure image pulls
2. **GitHub Workflow for Private ACR** - Automated image building and deployment
3. **User Assigned Identity** - Unified authentication for Container Apps

---

## Phase 1: Infrastructure Deployment

### Prerequisites
- [ ] Azure CLI installed and logged in: `az account show`
- [ ] PowerShell 7+ (Core)
- [ ] Subscription confirmed and selected
- [ ] Resource Group will be created automatically

### Deployment Steps

1. **Run Enhanced Infrastructure Deployment**
   ```powershell
   cd infra
   .\deploy.ps1
   ```
   
   Expected prompts:
   - Select Azure subscription (if multiple)
   - Confirm resource group name: `rg-todomanagement-dev`
   - Select location: `japaneast` (or your region)
   
   - [ ] Deployment completed successfully
   - [ ] Check for errors - verify all resources deployed:
     - [ ] Virtual Network (10.0.0.0/16)
     - [ ] PostgreSQL Flexible Server (v17)
     - [ ] Azure Container Registry (Premium)
     - [ ] Log Analytics Workspace
     - [ ] Container App Environment
     - [ ] User Assigned Identity (NEW)
     - [ ] ACR Private Endpoint (NEW)
     - [ ] ACR Private DNS Zone (NEW)

2. **Save Deployment Outputs**
   ```powershell
   # Deployment outputs saved to deployment-outputs.json
   cat deployment-outputs.json | convertfrom-json | format-table
   ```
   
   - [ ] Note these critical values:
     - `userAssignedIdentityId` - for reference
     - `userAssignedIdentityPrincipalId` - for PostgreSQL role
     - `acrPrivateEndpointId` - for verification
     - `postgresqlHostname` - for connections
     - `acrLoginServer` - for image pulls

### Validation

3. **Verify Private Endpoint Creation**
   ```powershell
   # Check private endpoint exists
   az network private-endpoint list --resource-group rg-todomanagement-dev -o table
   ```
   
   - [ ] ACR private endpoint appears in list
   - [ ] Status should be "Succeeded"

4. **Verify Private DNS Zone**
   ```powershell
   # Check DNS zone created
   az network private-dns zone list --resource-group rg-todomanagement-dev
   
   # Check DNS A records
   az network private-dns record-set a list --resource-group rg-todomanagement-dev --zone-name privatelink.azurecr.io
   ```
   
   - [ ] `privatelink.azurecr.io` zone exists
   - [ ] A record points to private IP (10.0.x.x)

5. **Verify User Assigned Identity**
   ```powershell
   # Get UAI details
   az identity show --resource-group rg-todomanagement-dev --name uai-todomanagement-dev
   ```
   
   - [ ] UAI display name shows "uai-todomanagement-dev"
   - [ ] clientId and principalId are populated
   - [ ] No errors in creation

6. **Verify RBAC Role Assignments**
   ```powershell
   # Check AcrPull role assigned to UAI
   az role assignment list \
     --resource-group rg-todomanagement-dev \
     --assignee-principal-type ServicePrincipal | where {$_.roleDefinitionName -eq 'AcrPull'}
   ```
   
   - [ ] AcrPull role shows assigned to UAI principal

---

## Phase 2: GitHub Configuration

### Prerequisites
- [ ] GitHub repository created and cloned locally
- [ ] Pushed all code from your workspace to GitHub
- [ ] Have admin access to GitHub repository settings

### Setup GitHub Secrets (Automated Method - Recommended)

7. **Run GitHub Secrets Setup Script**
   ```powershell
   cd infra
   .\setup-github-secrets.ps1
   ```
   
   If prompted:
   - [ ] Select Resource Group: `rg-todomanagement-dev`
   - [ ] Select ACR: `acrname` (or create new Service Principal)
   - [ ] Accept federated credentials for GitHub OIDC
   - [ ] Review service principal details
   
   - [ ] Script outputs GitHub Secrets needed
   - [ ] Copy the exact secrets shown in output

### Configure GitHub Secrets (Manual)

8. **Add Secrets to GitHub Repository**
   
   Go to GitHub Repository → Settings → Secrets and variables → Actions
   
   Create these secrets (values from script output):
   - [ ] `AZURE_CLIENT_ID` - Service Principal client ID
   - [ ] `AZURE_TENANT_ID` - Your Azure tenant ID  
   - [ ] `ACR_LOGIN_SERVER` - ACR login server (e.g., `acr-name.azurecr.io`)
   
   For federated credential (recommended):
   - [ ] No `AZURE_CLIENT_SECRET` needed (uses federated token)
   
   Or if using client secret:
   - [ ] `AZURE_CLIENT_SECRET` - Service Principal credential

9. **Verify GitHub Secrets**
   ```
   https://github.com/<your-org>/<your-repo>/settings/secrets/actions
   ```
   
   - [ ] All required secrets appear in list
   - [ ] No typos in secret names

### Alternative: Manual Service Principal Setup

If you prefer not to use the script:

10. **Create Service Principal Manually**
    ```powershell
    # Create service principal
    az ad sp create-for-rbac --name "acr-github-action" --role "AcrPush" \
      --scopes "/subscriptions/<subscription-id>/resourceGroups/rg-todomanagement-dev/providers/Microsoft.ContainerRegistry/registries/<acr-name>"
    ```
    
    - [ ] Note clientId, tenantId, and password
    - [ ] Set AZURE_CLIENT_SECRET secret in GitHub

11. **Setup Federated Credentials (Optional - More Secure)**
    ```powershell
    # Setup OIDC federation for GitHub
    $spId = az ad sp show --id "<client-id>" --query id -o tsv
    
    az identity federated-identity-credential create \
      --name "github-action" \
      --identity-name "uai-todomanagement-dev" \
      --resource-group "rg-todomanagement-dev" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "repo:<your-org>/<your-repo>:ref:refs/heads/main"
    ```
    
    - [ ] Federated credential created successfully
    - [ ] No AZURE_CLIENT_SECRET needed

---

## Phase 3: PostgreSQL Configuration

### Prerequisites
- [ ] PostgreSQL admin password from deployment outputs
- [ ] psql client installed (or use Cloud Shell)
- [ ] UAI principal ID from deployment outputs

### Setup Entra ID Authentication

12. **Connect to PostgreSQL as Admin**
    ```bash
    # Get PostgreSQL hostname from outputs
    POSTGRES_SERVER="<your-postgres-server>.postgres.database.azure.com"
    
    psql --host=$POSTGRES_SERVER \
         --username=postgres \
         --dbname=tododb \
         --set sslmode=require
    ```
    
    - [ ] Connected to PostgreSQL successfully
    - [ ] You see the `tododb=#` prompt

13. **Create PostgreSQL Role for UAI**
    
    In PostgreSQL console:
    ```sql
    -- Create role for UAI
    CREATE ROLE "uai-todomanagement-dev" LOGIN;
    
    -- Grant database connection
    GRANT CONNECT ON DATABASE tododb TO "uai-todomanagement-dev";
    
    -- Grant schema usage
    GRANT USAGE ON SCHEMA public TO "uai-todomanagement-dev";
    
    -- Grant table permissions
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "uai-todomanagement-dev";
    
    -- Grant sequence permissions
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO "uai-todomanagement-dev";
    
    -- Set default permissions for future tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "uai-todomanagement-dev";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO "uai-todomanagement-dev";
    ```
    
    - [ ] All SQL commands executed without errors
    - [ ] `CREATE ROLE` shows success message

14. **Verify Role Creation**
    ```sql
    \du
    ```
    
    - [ ] "uai-todomanagement-dev" appears in role list
    - [ ] Has "Login", "Can initiate streaming replication" attributes

15. **Exit PostgreSQL**
    ```sql
    \q
    ```
    
    - [ ] Returned to command prompt

---

## Phase 4: Application Configuration

### Update Application Code

16. **Update Python Requirements** (src/api/requirements.txt)
    ```
    sqlalchemy==2.0.x
    psycopg2-binary==2.9.x
    azure-identity==1.x
    azure-postgresql==0.1.x
    ```
    
    - [ ] Added azure-identity for managed identity support
    - [ ] Requirements file updated

17. **Update Database Connection** (src/api/database.py)
    
    Replace hardcoded passwords with managed identity:
    ```python
    from azure.identity.aio import DefaultAzureCredential
    import os
    
    async def get_db_token():
        """Get fresh PostgreSQL token using managed identity"""
        credential = DefaultAzureCredential()
        token = await credential.get_token("https://ossrdbms-aad.database.windows.net/.default")
        return token.token
    
    async def get_database_engine():
        """Create SQLAlchemy engine with Azure AD auth"""
        host = os.getenv("POSTGRES_HOST", "<server>.postgres.database.azure.com")
        token = await get_db_token()
        
        url = f"postgresql+psycopg2://uai-todomanagement-dev:{token}@{host}:5432/tododb?sslmode=require"
        
        engine = create_engine(url, echo=False)
        return engine
    ```
    
    - [ ] Database module updated to use managed identity
    - [ ] No hardcoded passwords in code
    - [ ] Token refresh mechanism works

18. **Update Container App Environment Variables**
    
    Via Azure Portal or CLI:
    ```powershell
    az containerapp update \
      --name container-app-name \
      --resource-group rg-todomanagement-dev \
      --set-env-vars \
        POSTGRES_HOST="<server>.postgres.database.azure.com" \
        POSTGRES_DB="tododb" \
        POSTGRES_USER="uai-todomanagement-dev"
    ```
    
    - [ ] Environment variables set in Container App
    - [ ] Removed POSTGRES_PASSWORD (uses tokens)

19. **Verify UAI is Assigned to Container App**
    
    In Azure Portal:
    - Navigate to Container App → Settings → Identity
    
    - [ ] "User assigned" tab shows "uai-todomanagement-dev"
    - [ ] Status shows "Active"

---

## Phase 5: GitHub Workflow Testing

### Prepare Code for Workflow

20. **Ensure Dockerfile Uses Image Registry Variable**
    
    In `src/api/Dockerfile`:
    ```dockerfile
    # Multi-stage build
    FROM python:3.11-slim as builder
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install --no-cache-dir -r requirements.txt
    
    FROM python:3.11-slim
    WORKDIR /app
    COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
    COPY . .
    EXPOSE 8000
    CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    ```
    
    - [ ] Dockerfile exists and is correct
    - [ ] Base images use correct versions

21. **Verify GitHub Workflow File**
    
    Check `.github/workflows/build-deploy-acr.yml`:
    - [ ] Container App name matches your app name
    - [ ] Resource group matches: `rg-todomanagement-dev`
    - [ ] ACR login server in secrets matches
    - [ ] Image name is consistent throughout

22. **Push Code to GitHub**
    ```bash
    git add .
    git commit -m "Configure managed identity and ACR deployment"
    git push origin main
    ```
    
    - [ ] Code pushed to GitHub main branch
    - [ ] GitHub Actions workflow triggers automatically

23. **Monitor Workflow Execution**
    
    In GitHub repository:
    - Go to **Actions** tab
    - Click on latest workflow run
    
    - [ ] Workflow starts executing (watch for status)
    - [ ] Build step completes successfully
    - [ ] Docker image tagged with timestamp
    - [ ] Image pushed to ACR via private endpoint
    - [ ] Container App updated with new image
    - [ ] Deployment succeeds (green checkmark)

---

## Phase 6: Verification & Testing

### Test Database Connectivity

24. **From Container App Environment**
    ```bash
    # Execute shell in container
    az containerapp exec \
      --name container-app-name \
      --resource-group rg-todomanagement-dev
    
    # Test database connection
    python -c "from database import get_database_engine; print('DB OK')"
    ```
    
    - [ ] Container shell is accessible
    - [ ] Database connection succeeds
    - [ ] No authentication errors

25. **Test Image Pull from ACR**
    
    In Container App logs:
    ```powershell
    az containerapp logs show \
      --name container-app-name \
      --resource-group rg-todomanagement-dev \
      --container container-name
    ```
    
    - [ ] No authentication errors for image pull
    - [ ] Image pulled successfully via private endpoint
    - [ ] Application started correctly

### Test ACR Private Endpoint

26. **Verify Private DNS Resolution**
    ```powershell
    # From within VNet (Container App subnet)
    nslookup <acr-name>.azurecr.io
    
    # Should resolve to 10.0.x.x (private IP), NOT public IP
    ```
    
    - [ ] DNS resolves to private IP (10.0.x.x range)
    - [ ] Public IP NOT returned

27. **Verify ACR Login Token**
    ```bash
    # From Container App
    az acr login --name <acr-name> --expose-token
    
    # Or test pull
    docker pull <acr-name>.azurecr.io/todomanagement:latest
    ```
    
    - [ ] Login succeeds with managed identity
    - [ ] Image pulls without public internet

---

## Phase 7: Documentation & Cleanup

### Documentation

28. **Record Critical Information**
    
    Save to secure location (e.g., team wiki):
    - [ ] Resource Group name: `rg-todomanagement-dev`
    - [ ] ACR Login Server: `<your-acr>.azurecr.io`
    - [ ] PostgreSQL Server: `<your-server>.postgres.database.azure.com`
    - [ ] Container App name: `<app-name>`
    - [ ] UAI name: `uai-todomanagement-dev`
    - [ ] UAI Principal ID: `<guid>`
    - [ ] GitHub Secrets configured
    - [ ] PostgreSQL roles configured

29. **Review Documentation Files**
    - [ ] Read `infra/ACR_GITHUB_INTEGRATION.md` for architecture details
    - [ ] Read `infra/POSTGRESQL_ENTRA_ID_AUTH.md` for DB setup details
    - [ ] Bookmark troubleshooting sections

### Cleanup (if needed)

30. **Remove Old Resources** (if migrating)
    ```powershell
    # Warning: This deletes all resources in the group!
    az group delete --name rg-todomanagement-old --yes
    ```
    
    - [ ] Only delete if you've verified new setup is working
    - [ ] Backup any data first

---

## Troubleshooting

### Deployment Failures

**Error: "Private Endpoint creation failed"**
- Verify ACR has Premium tier (Standard/Basic don't support private endpoints)
- Check subnet is available with space for private endpoint
- Ensure delegations are correct on subnet

**Error: "UAI role assignment failed"**
- Verify UAI exists in resource group
- Check subscription has Microsoft.Authorization/roleAssignments permission
- Try using Azure Portal to manually assign AcrPull role

### GitHub Workflow Issues

**Workflow: Authentication to ACR failed**
- Verify secrets in GitHub match actual values
- Check federated credentials are configured (if not using client secret)
- Ensure Service Principal has AcrPush role on ACR

**Workflow: Container App update failed**
- Verify container app exists in specified resource group
- Check App name exactly matches (case-sensitive)
- Ensure image tag format is correct: `acr.azurecr.io/app:tag`

### PostgreSQL Issues

**Error: "FATAL: no PostgreSQL user name specified"**
- Verify username in connection string: "uai-todomanagement-dev"
- Check role was created with `CREATE ROLE` command

**Error: "permission denied for schema public"**
- Run GRANT USAGE ON SCHEMA commands again
- Check role is logged in correctly

**Error: "Token expired"**
- Token refresh is automatic via Azure SDK
- Ensure container has managed identity assigned
- Check UAI has "Login" permission in PostgreSQL

### Network Issues

**Error: "Private endpoint DNS not resolving"**
- Check private DNS zone is linked to VNet
- Verify A record exists in DNS zone
- From container: `nslookup <acr>.azurecr.io` should resolve to 10.0.x.x

**Error: "Cannot reach ACR from Container App"**
- Verify private endpoint is in "Succeeded" state
- Check network security group rules allow HTTPS outbound
- Ensure subnet delegate allows Microsoft.App/environments

---

## Success Criteria

When complete, you should have:

✅ **Infrastructure:**
- [ ] ACR Private Endpoint created and functioning
- [ ] PostgreSQL Entra ID authentication enabled
- [ ] Container App using User Assigned Identity
- [ ] All resources in resource group deployed

✅ **Security:**
- [ ] No hardcoded database passwords
- [ ] GitHub using federated token (no client secret)
- [ ] ACR accessible only via private endpoint from VNet
- [ ] PostgreSQL authenticates via Entra ID token

✅ **Automation:**
- [ ] GitHub workflow runs on every code push
- [ ] Automatic Docker image build and push to ACR
- [ ] Automatic deployment to Container App
- [ ] Zero-downtime deployment works

✅ **Connectivity:**
- [ ] Container App authenticates to ACR via UAI
- [ ] Container App authenticates to PostgreSQL via UAI
- [ ] No manual token management needed

---

## Quick Reference Commands

```powershell
# Deploy infrastructure
.\deploy.ps1

# Setup GitHub secrets and service principal
.\setup-github-secrets.ps1

# Check deployment status
az deployment group show --resource-group rg-todomanagement-dev --name infra-deployment

# View Container App logs
az containerapp logs show --name container-app-name --resource-group rg-todomanagement-dev

# Get deployment outputs
cat deployment-outputs.json | convertfrom-json | format-table

# Test PostgreSQL connection
psql --host=<server>.postgres.database.azure.com --username=postgres --dbname=tododb --set sslmode=require

# Check ACR private endpoint
az network private-endpoint list --resource-group rg-todomanagement-dev -o table

# View GitHub Actions history
# https://github.com/<org>/<repo>/actions
```

---

## Support & References

- **ACR + GitHub Integration**: See `infra/ACR_GITHUB_INTEGRATION.md`
- **PostgreSQL Entra ID Setup**: See `infra/POSTGRESQL_ENTRA_ID_AUTH.md`
- **Infrastructure Code**: See `infra/main.bicep`
- **GitHub Workflow**: See `.github/workflows/build-deploy-acr.yml`

---

**Last Updated**: After infrastructure enhancement with private endpoints and managed identities
**Status**: Ready for deployment
