# 🚀 Todo Management アプリケーション - デプロイメント完全ガイド

このドキュメントは、GitHub Template からプロジェクトを Clone し、Azure に デプロイメントするまでの全プロセスを日本語で説明します。

**所要時間：約 30～40 分**

---

## 📋 前提条件

- Azure サブスクリプション（Contributor 以上の権限）
- GitHub アカウント
- Git がインストール済み
- インターネット接続

---

## Step 1️⃣ GitHub Template からプロジェクトを Clone

### 1.1 テンプレートリポジトリにアクセス

1. GitHub で次のリポジトリを開きます（またはご自身の Template Repository）
   - URL: `https://github.com/Liminghao0922/todomanagement`

### 1.2 "Use this template" をクリック

1. リポジトリページの右上にある **"Use this template"** ボタンをクリック
2. **"Create a new repository"** を選択
3. 以下の情報を入力します：
   - **Repository name**: 任意の名前（例：`my-todo-app`）
   - **Description**: 任意（例：`My Todo Management App`）
   - **Visibility**: `Public` または `Private` を選択
   - **Include all branches**: チェック不要

4. **"Create repository from template"** をクリック

---

## Step 2️⃣ Azure Cloud Shell を開く（PowerShell）

### 2.1 Azure Portal にログイン

1. https://portal.azure.com にアクセス
2. Azure アカウントでログイン

### 2.2 Cloud Shell を起動

1. ポータル上部の **Cloud Shell** アイコン（`>_`）をクリック
2. ターミナルが起動します
3. **環境を "PowerShell" に切り替え**（デフォルトが Bash の場合）
   - 左上の環境選択ドロップダウンから **"PowerShell"** を選択

### 2.3 サブスクリプションを確認

```powershell
# 現在のサブスクリプション確認
az account show

# 別のサブスクリプションに切り替える場合
az account set --subscription "<subscription-id>"
```

---

## Step 3️⃣ Cloud Shell 内でリポジトリをダウンロード

### 3.1 リポジトリをクローン

```powershell
# リポジトリをクローン
git clone https://github.com/[your-username]/[your-repo-name].git
cd [your-repo-name]

# 確認
ls
# 出力:
# src/
# infra/
# docs/
# README.md
# など
```

### 3.2 ローカルで事前に設定を変更した場合

ローカルマシンで先に変更してから Push した場合、Cloud Shell で最新のコードを取得します：

```powershell
# Cloud Shell で最新のコードを取得
git pull origin main
```

---

## Step 4️⃣ 基本設定を修正（Cloud Shell 内）

### 4.1 パラメータファイルを編集

```powershell
# パラメータファイルを確認
cat infra/parameters.json
```

**infra/parameters.json** 内容（デフォルト値）：

```json
{
  "parameters": {
    "location": {
      "value": "japaneast"  // ← 必要に応じて変更（例：eastus）
    },
    "environment": {
      "value": "dev"  // dev / staging / prod
    },
    "projectName": {
      "value": "todomanagement"  // ← リソース名用
    },
    "postgresqlAdminPassword": {
      "value": "Change@Me123!"  // ⚠️ 強力なパスワードに変更！
    }
  }
}
```

### 4.2 Cloud Shell 内で編集（オプション）

```powershell
# Nano エディタで編集
nano infra/parameters.json

# または PowerShell で直接編集
$json = Get-Content infra/parameters.json | ConvertFrom-Json
$json.parameters.postgresqlAdminPassword.value = "YourStrongPassword@123"
$json | ConvertTo-Json | Set-Content infra/parameters.json
```

**重要な変更項目：**

| 項目 | 説明 | 例 |
|------|------|-----|
| `location` | Azure リージョン | japaneast / eastus / westeurope |
| `environment` | 環境識別子 | dev (開発) / staging / prod (本番) |
| `projectName` | リソース名の接頭辞 | myapp / mycompany-todo |
| `postgresqlAdminPassword` | PostgreSQL 管理者パスワード | Str0ng@Password2024! |

### 4.3 ⚠️ PostgreSQL パスワードについて

**重要な注釈**：

- **初期化時のみ使用**: `postgresqlAdminPassword` は PostgreSQL サーバー作成時**のみ**必要です
- **アプリケーションアクセス**: このプロジェクトは **Managed Identity** を使用しています
  - ✅ アプリケーションはパスワード**なし**で PostgreSQL にアクセス
  - ✅ より安全な認証方式です
  - ✅ 認証情報を環境変数に保存する必要なし
- **パスワード要件**: 以下の条件を満たす必要があります
  - 8 文字以上
  - 大文字を含む
  - 小文字を含む
  - 数字を含む
  - 記号を含む

**例**: `Str0ng@Password2024!`

---

## Step 5️⃣ インフラストラクチャをデプロイ

### 5.1 リソースグループを作成

```powershell
# 変数を設定
$resourceGroupName = "rg-todomanagement-dev"
$location = "japaneast"

# リソースグループを作成
az group create `
  --name $resourceGroupName `
  --location $location

# 確認
az group list --output table
```

### 5.2 デプロイスクリプトを実行

```powershell
# infra ディレクトリに移動
cd infra

# PowerShell スクリプトを実行
# Windows PowerShell では以下のコマンドで実行可能にする
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# デプロイを実行
.\deploy.ps1 -ResourceGroupName $resourceGroupName -Location $location
```

> **注意**：Cloud Shell の PowerShell では実行ポリシーが既に設定されているため、そのまま実行できます。

### 5.3 デプロイ完了を確認

```powershell
# デプロイの状態を確認
az deployment group list -g $resourceGroupName --query "[].properties.outputs" -o json

# 出力例：
# {
#   "postgresqlServerName": {"value": "postgres-todomanagement-xxxxx"},
#   "containerRegistryName": {"value": "acrtodomanagementxxxxx"},
#   "containerAppEnvironmentName": {"value": "cae-todomanagement-dev"}
# }
```

**出力から以下の情報を記録してください：**

```
📝 デプロイ情報（後で使用）
- PostgreSQL Server Name: postgres-todomanagement-xxxxx
- ACR Name: acrtodomanagementxxxxx
- Container App Environment: cae-todomanagement-dev
- Resource Group: rg-todomanagement-dev
```

---

## Step 6️⃣ Entra ID アプリ登録（GitHub Actions 用）

### 6.1 Azure Portal で Service Principal を作成

Cloud Shell で以下を実行：

```powershell
# 変数を設定
$subscriptionId = $(az account show --query id -o tsv)
$resourceGroup = "rg-todomanagement-dev"
$spName = "github-todomanagement-ci"

# Service Principal を作成
$sp = az ad sp create-for-rbac `
  --name $spName `
  --role "Contributor" `
  --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
  --json-auth | ConvertFrom-Json

# JSON 形式で出力（後で使用）
$sp | ConvertTo-Json
```

**出力をコピーしてメモしておきます**（次のステップで使用）：

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  ...
}
```

---

## Step 7️⃣ GitHub Secrets & Variables を設定

### 7.1 GitHub リポジトリの Settings を開く

1. GitHub リポジトリのページを開く
2. **Settings** → **Secrets and variables** → **Secrets** をクリック

### 7.2 Secret を追加

**Name**: `AZURE_CREDENTIALS`  
**Value**: Step 6.1 でコピーした JSON 全体をペースト

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "...",
  ...
}
```

### 7.3 Variables を追加

**Settings** → **Secrets and variables** → **Variables** をクリック

以下の Variables を追加します：

| Variable Name | Value | 説明 |
|---|---|---|
| `ACR_NAME` | `acrtodomanagementxxxxx` | デプロイ出力から取得 |
| `RESOURCE_GROUP` | `rg-todomanagement-dev` | デプロイ出力から取得 |
| `POSTGRES_SERVER` | `postgres-todomanagement-xxxxx` | デプロイ出力から取得 |
| `POSTGRES_DB` | `tododb` | デフォルト |
| `POSTGRES_USER` | `postgres` | デフォルト |
| `AZURE_CLIENT_ID` | `[Entra ID App ID]` | Azure Portal から取得 |
| `AZURE_TENANT_ID` | `[租户 ID]` | Azure Portal から取得 |
| `AZURE_REDIRECT_URI` | `https://[web-app-url]` | デプロイ後に取得 |
| `API_BASE_URL` | `https://[api-app-url]` | デプロイ後に取得 |
| `USER_ASSIGNED_IDENTITY_CLIENT_ID` | `[Managed Identity Client ID]` | デプロイ出力から取得 |

**追加方法**：
1. **New repository variable** をクリック
2. **Name** に変数名を入力
3. **Value** に値を入力
4. **Add variable** をクリック

---

## Step 8️⃣ コードをコミット・プッシュ

### 8.1 設定ファイルを修正（ローカル）

ローカルマシンで以下を実行：

```bash
# ローカルで parameter.json を編集（必要に応じて）
# または .env ファイルが追加されていることを確認

# 変更を確認
git status

# 出力例：
# On branch main
# Changes not staged for commit:
#   modified: infra/parameters.json
```

### 8.2 コミット・プッシュ

```bash
# 変更をステージング
git add .

# コミット
git commit -m "Configure infrastructure parameters and GitHub Actions variables"

# メインブランチにプッシュ
git push origin main
```

確認：
```bash
# リモート確認
git log --oneline
# 出力に最新のコミットが表示されます
```

---

## Step 9️⃣ GitHub Actions で自動デプロイ

### 9.1 Workflow の実行を確認

1. GitHub リポジトリのページから **Actions** タブをクリック
2. 以下のワークフローが表示されます：
   - `Build and Deploy API to ACR`
   - `Build and Deploy Web to ACR`

### 9.2 Workflow の自動実行を待つ

**トリガー条件**：
- `main` ブランチへの `push` 時に自動実行
- `src/api/` または `.github/workflows/build-deploy-api.yml` が変更された場合 → API ワークフロー実行
- `src/web/` または `.github/workflows/build-deploy-web.yml` が変更された場合 → Web ワークフロー実行

### 9.3 実行状況を確認

```
Actions ページで以下を確認：

✅ チェックマーク
├─ Checkout code
├─ Log in to Azure
├─ Build and push image to ACR
└─ Deploy to Container App
```

**所要時間**：API & Web で各 5～10 分

### 9.4 Workflow が失敗した場合

❌ エラーが表示された場合：

1. **Workflow をクリック**して詳細を確認
2. **失敗したステップ** をクリック
3. **エラーログ** を確認
4. よくあるエラー：
   - `AZURE_CREDENTIALS` が設定されていない
   - `RESOURCE_GROUP` Variable が間違っている
   - Container App Environment 名が一致していない

---

## Step 🔟 Web アプリケーションにアクセス

### 🔟.1 Container App URL を取得

Cloud Shell で実行：

```powershell
# Web Container App の URL を取得
az containerapp show `
  -n todomanagement-web `
  -g rg-todomanagement-dev `
  --query "properties.configuration.ingress.fqdn" `
  -o tsv

# 出力例：
# todomanagement-web.abc123def.japaneast.azurecontainerapps.io
```

完全な URL：

```
https://todomanagement-web.abc123def.japaneast.azurecontainerapps.io
```

### 🔟.2 ブラウザでアクセス

1. 上記 URL をブラウザのアドレスバーにコピー・ペースト
2. **Enter** キーを押す
3. Todo Management アプリケーションが表示されます ✅

### 🔟.3 機能を確認

- **🔐 Login ボタン**をクリック
- Microsoft/Azure AD で認証
- Todo リストが表示される
- New Todo の作成、編集、削除が可能

---

## Step 1️⃣1️⃣ トラブルシューティング

### 問題: Web にアクセスできない

```powershell
# Container App のステータス確認
az containerapp show `
  -n todomanagement-web `
  -g rg-todomanagement-dev `
  --query "properties.workloadProfileName"

# ログを確認
az containerapp logs show `
  -n todomanagement-web `
  -g rg-todomanagement-dev `
  --tail 50
```

### 問題: API に接続できない

```powershell
# API の健康チェック
curl https://todomanagement-api.abc123def.japaneast.azurecontainerapps.io/health

# 出力例：
# {"status":"healthy","service":"Todo Management API","version":"2.0.0"}
```

### 問題: CORS エラー

API のエンドポイント設定を確認：

```python
# src/api/main.py 内の CORS 設定を確認
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 完了チェックリスト ✅

- [ ] GitHub から Template をクローン
- [ ] Azure Cloud Shell を起動（PowerShell）
- [ ] リポジトリをダウンロード
- [ ] infra/parameters.json を修正
- [ ] `az group create` でリソースグループ作成
- [ ] `.\deploy.ps1` でインフラをデプロイ
- [ ] .env ファイルを設定
- [ ] Service Principal を作成
- [ ] GitHub Secrets に `AZURE_CREDENTIALS` を追加
- [ ] GitHub Variables を 9 個追加
- [ ] `git commit` と `git push`
- [ ] GitHub Actions が正常に実行
- [ ] Web アプリにアクセス可能
- [ ] Login 機能が動作

---

## よくあるコマンド参考

```powershell
# ========== Azure CLI Commands ==========

# サブスクリプション確認
az account show

# リソースグループ一覧
az group list --output table

# Container App の URL 取得
az containerapp show -n todomanagement-web -g rg-todomanagement-dev --query "properties.configuration.ingress.fqdn" -o tsv

# Container App のログ確認
az containerapp logs show -n todomanagement-web -g rg-todomanagement-dev --tail 50

# リソースグループ削除（クリーンアップ）
az group delete --name rg-todomanagement-dev --yes --no-wait


# ========== Git Commands ==========

# 変更確認
git status

# 変更内容確認
git diff

# コミット・プッシュ
git add .
git commit -m "Your message"
git push origin main

# ブランチ確認
git branch -a

# リモート同期
git pull origin main
```

---

## 次のステップ

✨ デプロイ完了後：

1. **カスタマイズ**
   - `src/web/src/` で UI をカスタマイズ
   - `src/api/` でビジネスロジックを追加
   - 変更をコミット・プッシュで自動デプロイ

2. **本番環境準備**
   - 環境を `prod` に変更
   - より強力なデータベース SKU を選択
   - Entra ID テナントで認証設定

3. **モニタリング**
   - Azure Monitor でログ確認
   - Application Insights でパフォーマンス確認

4. **ドキュメント参照**
   - `docs/ARCHITECTURE_GUIDE.md` - アーキテクチャ詳細
   - `docs/GITHUB_CONFIG_SETUP.md` - GitHub 設定詳細
   - `README.md` - 本体ドキュメント

---

## サポート・お問い合わせ

質問や問題がある場合：

1. `docs/` フォルダの詳細ドキュメントを確認
2. GitHub Issues で報告
3. README.md の「参考与故障排査」を参照

---

**楽しいデプロイを！🚀**

作成日：2026-03-30  
バージョン：1.0
