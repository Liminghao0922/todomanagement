# 講師準備ガイド

[English](INSTRUCTOR_PREP_GUIDE.md) | [简体中文](INSTRUCTOR_PREP_GUIDE-zh_CN.md) | [日本語](INSTRUCTOR_PREP_GUIDE-ja_JP.md)

このドキュメントは講師向けです。ワークショップ前に Azure Container Registry を作成し、Azure Cloud Shell から ACR remote build を使って API/Web イメージを事前にビルドしてプッシュします。受講者は hands-on 中に講師が提供したイメージを選択するだけでよく、GitHub Actions もローカル Docker も不要です。

---

## 前提条件

- 講師が利用可能な Azure subscription を持っていること
- 講師が Azure Cloud Shell で `az` コマンドを実行できること
- 講師がこのリポジトリのソースコードを準備済みであること
- 講師に Resource Group と Azure Container Registry を作成する権限があること

> 注意: この手順では `az acr build` を使用します。ビルドは ACR 側で実行されるため、Cloud Shell に Docker をインストールする必要はありません。

---

## 1. Cloud Shell でソースコードを準備する

Azure Portal 右上の **Cloud Shell** を開き、**Bash** を選択します。

リポジトリが GitHub にある場合:

```bash
git clone <repository-url>
cd todomanagement
```

ソースコードが zip ファイルの場合:

```bash
unzip todomanagement.zip
cd todomanagement
```

ディレクトリ構成を確認します:

```bash
ls src/api/Dockerfile src/web/Dockerfile
```

---

## 2. 変数を設定する

実際のワークショップ環境に合わせて値を変更します:

```bash
SUBSCRIPTION_ID="<subscription-id>"
LOCATION="japaneast"
RESOURCE_GROUP="rg-todomanagement-instructor"
ACR_NAME="<globally-unique-acr-name>"
IMAGE_TAG="workshop-$(date +%Y%m%d)"
API_IMAGE="todomanagement-api:${IMAGE_TAG}"
WEB_IMAGE="todomanagement-web:${IMAGE_TAG}"
```

要件:

- `ACR_NAME` はグローバルに一意であること
- 小文字英数字のみ使用すること
- 長さは 5 から 50 文字
- `-` や `_` は使用しないこと

ACR 名が利用可能か確認します:

```bash
az acr check-name --name "$ACR_NAME"
```

subscription を選択します:

```bash
az account set --subscription "$SUBSCRIPTION_ID"
```

---

## 3. Resource Group と ACR を作成する

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic
```

ACR admin user は無効のままにします。このワークショップでは、Container Apps が system-assigned managed identity を使って ACR からイメージを pull します。

```bash
az acr show \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "{loginServer:loginServer, adminUserEnabled:adminUserEnabled}" \
  --output table
```

> ワークショップ前に、各受講者アカウントへ講師 ACR の Owner ロールを付与します。これは、受講者が Azure Portal から必要な `AcrPull` role assignment を自分で作成できるようにするための、ワークショップ向けの簡略化です。Container App の実行時 identity に必要なのは引き続き `AcrPull` だけです。本番環境では最小権限の原則に従い、アプリケーション利用者に広い Owner 権限を付与せず、プラットフォーム管理者または自動化により、対象の Container App managed identity にのみ `AcrPull` を付与してください。

---

## 4. API image を remote build する

リポジトリルートから実行します:

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$API_IMAGE" \
  --file src/api/Dockerfile \
  src/api
```

説明:

- `src/api` が build context
- ローカル Docker は不要
- ACR remote build はビルド後、自動的に現在の ACR へイメージをプッシュします

---

## 5. Web image を remote build する

リポジトリルートから実行します:

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image "$WEB_IMAGE" \
  --file src/web/Dockerfile \
  src/web
```

説明:

- `src/web` が build context
- Web image のビルド時に `VITE_AZURE_CLIENT_ID`、`VITE_AZURE_AUTHORITY`、`VITE_AZURE_REDIRECT_URI` を渡す必要はありません
- 受講者は Web Container App 作成時に client ID と authority を環境変数として設定します。Redirect URI は現在の Web app URL が既定値になります。

---

## 6. イメージを検証する

リポジトリを確認します:

```bash
az acr repository list \
  --name "$ACR_NAME" \
  --output table
```

API tags を確認します:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-api \
  --output table
```

Web tags を確認します:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository todomanagement-web \
  --output table
```

login server を取得します:

```bash
LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --query loginServer \
  --output tsv)

echo "$LOGIN_SERVER"
```

完全なイメージ名を出力します:

```bash
echo "API image: ${LOGIN_SERVER}/${API_IMAGE}"
echo "Web image: ${LOGIN_SERVER}/${WEB_IMAGE}"
```

---

## 7. 受講者へ提供する情報を取得する

次の情報を受講者に共有します:

| Item | Value |
| ---- | ----- |
| Registry login server | `${LOGIN_SERVER}` |
| API image | `${LOGIN_SERVER}/${API_IMAGE}` |
| Web image | `${LOGIN_SERVER}/${WEB_IMAGE}` |

---

## 8. 受講者が Web Container App に設定する環境変数

Web image は runtime configuration に対応しています。受講者が Web Container App を作成するときに設定します:

| Name | Example |
| ---- | ------- |
| `API_PROXY_TARGET` | `https://app-todomanagement-api.internal.<environment-domain>.azurecontainerapps.io` |
| `VITE_AZURE_CLIENT_ID` | Microsoft Entra ID app registration client ID |
| `VITE_AZURE_AUTHORITY` | `https://login.microsoftonline.com/<tenant-id>` |

`VITE_AZURE_REDIRECT_URI` は任意です。未設定の場合、Web app は現在ブラウザーで開いている URL を redirect URI として使用します。

API image は build 時に環境変数を書き込む必要はありません。受講者は API Container App 作成時に hands-on guide に従って、データベースと managed identity 関連の環境変数を設定します。

---

## 9. ワークショップ前チェックリスト

- ACR 作成済み
- ACR admin user が無効のままであることを確認済み
- API image の remote build 成功済み
- Web image の remote build 成功済み
- `todomanagement-api` と `todomanagement-web` の tags を確認可能
- registry login server を記録済み
- 完全な API/Web image 名を受講者へ共有済み
- 受講者アカウントに講師 ACR の Owner ロールを付与済み

---

## よくある問題

### ACR 名が使用できない

グローバルに一意な名前に変更します。小文字英数字のみ使用してください。

```bash
az acr check-name --name "<new-acr-name>"
```

### `az acr build` が Dockerfile を見つけられない

現在のディレクトリがリポジトリルートであることを確認します:

```bash
pwd
ls src/api/Dockerfile src/web/Dockerfile
```

### Web サインイン設定が反映されない

受講者が Web Container App に次の環境変数を設定し、新しい revision を作成済みであることを確認します:

- `VITE_AZURE_CLIENT_ID`
- `VITE_AZURE_AUTHORITY`

あわせて、受講者が開いている Web URL が Microsoft Entra ID app registration の redirect URI に追加されていることを確認します。

### 受講者がイメージを pull できない

確認項目:

- Container App の registry login server が正しい
- Container App で system-assigned managed identity が有効化されている
- Container App identity に講師 ACR の `AcrPull` ロールが付与されている
- image 名が完全な registry prefix を含んでいる。例: `myacr.azurecr.io/todomanagement-web:workshop-20260706`
