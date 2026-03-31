# 🔑 GitHub Variables 配置脚本（更新版）
# 用于配置部署所需的全部 GitHub Variables

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,  # 格式：owner/repo
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,  # GitHub Personal Access Token
    
    [Parameter(Mandatory=$false)]
    [string]$AzureClientId,  # Azure Entra ID 应用 Client ID
    
    [Parameter(Mandatory=$false)]
    [string]$AzureTenantId,  # Azure 租户 ID
    
    [Parameter(Mandatory=$false)]
    [string]$RedirectUri,  # OAuth 重定向 URI（web 应用 URL）
    
    [Parameter(Mandatory=$false)]
    [string]$ApiBaseUrl,  # API 服务基础 URL

    [Parameter(Mandatory=$false)]
    [string]$UserAssignedIdentityClientId  # 用户分配托管标识 Client ID
)

# 如果未提供所有参数，进行交互式提示
if (-not $AzureClientId) {
    Write-Host "`n📋 请获取以下信息，或从 Azure Portal 和部署中查找：`n"
    Write-Host "1. Azure Entra ID App Client ID"
    Write-Host "   获取位置：Azure Portal → Microsoft Entra ID → App registrations → 你的应用 → Application (client) ID"
    $AzureClientId = Read-Host "   输入 VITE_AZURE_CLIENT_ID"
}

if (-not $AzureTenantId) {
    Write-Host "`n2. Azure 租户 ID"
    Write-Host "   获取位置：Azure Portal → Microsoft Entra ID → App registrations → 你的应用 → Directory (tenant) ID"
    $AzureTenantId = Read-Host "   输入 AZURE_TENANT_ID"
}

if (-not $RedirectUri) {
    Write-Host "`n3. OAuth 重定向 URI（部署后的 web 应用完整 URL）"
    Write-Host "   示例：https://todomanagement-web.xxxxxxx.japaneast.azurecontainerapps.io"
    $RedirectUri = Read-Host "   输入 AZURE_REDIRECT_URI"
}

if (-not $ApiBaseUrl) {
    Write-Host "`n4. API 服务基础 URL"
    Write-Host "   示例：https://todomanagement-api.xxxxxxx.japaneast.azurecontainerapps.io"
    $ApiBaseUrl = Read-Host "   输入 API_BASE_URL"
}

if (-not $UserAssignedIdentityClientId) {
    Write-Host "`n5. 用户分配托管标识 Client ID"
    Write-Host "   获取位置：Azure Portal → 你的资源组 → 托管标识 → 选择用户分配的标识 → 复制客户端 ID"
    $UserAssignedIdentityClientId = Read-Host "   输入 USER_ASSIGNED_IDENTITY_CLIENT_ID"
}

if (-not $GitHubToken) {
    Write-Host "`n🔐 GitHub 配置"
    Write-Host "如果想通过脚本自动配置 GitHub Variables，请提供 GitHub Personal Access Token"
    Write-Host "获取方式：GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)"
    Write-Host "需要权限：repo (full control)"
    $GitHubToken = Read-Host "   输入 GitHub Token (按 Enter 跳过，手动配置)"
}

# 显示配置摘要
Write-Host "`n" "=" * 60
Write-Host "📝 配置摘要"
Write-Host "=" * 60
Write-Host "Repository: $GitHubRepo"
Write-Host "VITE_AZURE_CLIENT_ID: $AzureClientId"
Write-Host "AZURE_TENANT_ID: $AzureTenantId"
Write-Host "AZURE_REDIRECT_URI: $RedirectUri"
Write-Host "API_BASE_URL: $ApiBaseUrl"
Write-Host "USER_ASSIGNED_IDENTITY_CLIENT_ID: $UserAssignedIdentityClientId"
Write-Host "=" * 60

$proceed = Read-Host "`n确认配置？(y/n)"
if ($proceed -ne "y") {
    Write-Host "取消配置"
    exit
}

# 如果有 GitHub Token，使用 API 自动配置
if ($GitHubToken) {
    Write-Host "`n正在配置 GitHub Variables..."
    
    $headers = @{
        "Authorization" = "token $GitHubToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $variables = @(
        @{ name = "AZURE_CLIENT_ID"; value = $AzureClientId }
        @{ name = "AZURE_TENANT_ID"; value = $AzureTenantId }
        @{ name = "AZURE_REDIRECT_URI"; value = $RedirectUri }
        @{ name = "API_BASE_URL"; value = $ApiBaseUrl }
        @{ name = "USER_ASSIGNED_IDENTITY_CLIENT_ID"; value = $UserAssignedIdentityClientId }
    )
    
    foreach ($var in $variables) {
        $body = @{
            name = $var.name
            value = $var.value
        } | ConvertTo-Json
        
        $apiUrl = "https://api.github.com/repos/$GitHubRepo/actions/variables/$($var.name)"
        
        try {
            Invoke-RestMethod -Uri $apiUrl -Method Put -Headers $headers -Body $body | Out-Null
            Write-Host "✅ $($var.name) 已设置"
        } catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                # 变量不存在，需要创建
                $createUrl = "https://api.github.com/repos/$GitHubRepo/actions/variables"
                Invoke-RestMethod -Uri $createUrl -Method Post -Headers $headers -Body $body | Out-Null
                Write-Host "✅ $($var.name) 已创建"
            } else {
                Write-Host "❌ 设置 $($var.name) 失败: $_"
            }
        }
    }
    
    Write-Host "`n✅ GitHub Variables 配置完成！"
} else {
    Write-Host "`n📌 请手动配置以下 Variables："
    Write-Host "进入 GitHub 仓库："
    Write-Host "1. Settings → Secrets and variables → Variables"
    Write-Host "2. 点击 'New repository variable' 并添加以下变量："
    Write-Host ""
    Write-Host "   | Variable Name | Value |"
    Write-Host "   |---|---|"
    Write-Host "   | AZURE_CLIENT_ID | $AzureClientId |"
    Write-Host "   | AZURE_TENANT_ID | $AzureTenantId |"
    Write-Host "   | AZURE_REDIRECT_URI | $RedirectUri |"
    Write-Host "   | API_BASE_URL | $ApiBaseUrl |"
    Write-Host "   | USER_ASSIGNED_IDENTITY_CLIENT_ID | $UserAssignedIdentityClientId |"
}

Write-Host "`n✅ 配置完成！现在可以重新运行 GitHub 工作流"
