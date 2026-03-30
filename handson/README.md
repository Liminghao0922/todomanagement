# 📚 Handson ドキュメント

このフォルダには、Todo Management アプリケーションをデプロイするための日本語ハンズオンガイドが含まれています。

---

## 📖 ドキュメント一覧

### 1️⃣ **DEPLOY_GUIDE_JAPANESE.md** - 完全ガイド ⭐ 必読

**内容**: GitHub Template から Azure へのデプロイまでの全 11 ステップを詳しく説明

**読者対象**: 初めてデプロイする方、詳しい説明が必要な方

**所要時間**: 30～40 分

**カバー内容**:
- Step 1: GitHub Template をクローン
- Step 2: Azure Cloud Shell を開く（PowerShell）
- Step 3: リポジトリをダウンロード
- Step 4: 基本設定を修正
- Step 5: インフラをデプロイ
- Step 6: 環境変数を設定
- Step 7: Entra ID アプリ登録
- Step 8: GitHub Secrets & Variables を設定
- Step 9: コードをコミット・プッシュ
- Step 10: GitHub Actions で自動デプロイ
- Step 11: Web アプリケーションにアクセス

**使い方**:
1. 最初から順に読む
2. 各ステップを実行
3. コマンド例をコピー・ペースト

---

### 2️⃣ **QUICK_REFERENCE_JAPANESE.md** - クイックリファレンス

**内容**: 最も重要な情報だけをまとめた 1 ページ参考資料

**読者対象**: 2 回目以降のデプロイ、急いでいる方

**所要時間**: 5 分で全体把握

**カバー内容**:
- 全体フロー図
- 重要な設定値チェックリスト
- よく使うコマンド集
- よくあるエラーと対応表
- 実行コマンド（コピペ用）

**使い方**:
1. 流れを確認したい → 全体フロー図を見る
2. コマンドを思い出したい → 実行コマンド セクション
3. エラーが出た → よくあるエラー表で対応検索

---

### 3️⃣ **TROUBLESHOOTING_JAPANESE.md** - トラブルシューティング

**内容**: デプロイ中に出会うさまざまな問題と解決方法

**読者対象**: エラーが発生した方

**所要時間**: 問題により異なる（5～30 分）

**カバー内容**:
- 問題 1: GitHub Actions が失敗する
- 問題 2: Web にアクセスできない
- 問題 3: API に接続できない
- 問題 4: ログイン機能が動作しない
- 問題 5: デプロイスクリプトが実行できない
- 問題 6: Git コマンドが失敗する
- 問題 7: Azure リソースが表示されない
- + 詳細なログ確認方法

**使い方**:
1. 発生している問題を探す
2. 診断方法を実行
3. 対応方法を試す
4. うまくいかない場合は詳細ログを確認

---

## 🎯 使い分けガイド

```
初めてのデプロイ？
    ↓
DEPLOY_GUIDE_JAPANESE.md を読む
（Step 1 から順に進める）
    ↓
成功！


2 回目以降のデプロイ？
    ↓
QUICK_REFERENCE_JAPANESE.md を見る
（流れを確認、コマンドをコピペ）
    ↓
成功！


エラーが出た？
    ↓
TROUBLESHOOTING_JAPANESE.md で解決方法を探す
    ↓
成功！
```

---

## ⏱️ タイムライン

| ステップ | 所要時間 |
|---------|---------|
| GitHub Clone | 2 分 |
| Cloud Shell 起動 | 1 分 |
| リポジトリダウンロード | 2 分 |
| 設定修正 | 3 分 |
| インフラ デプロイ | **15～20 分** ⏳ |
| 環境変数設定 | 3 分 |
| Entra ID 設定 | 3 分 |
| GitHub 設定 | 5 分 |
| Git コミット・プッシュ | 2 分 |
| GitHub Actions 実行 | **10～15 分** ⏳ |
| Web アクセス | 1 分 |
| **合計** | **約 40～50 分** |

> **⏳** = 待機時間が長いため、この間に他のタスクを進められます

---

## 📊 主要な設定値

### infra/parameters.json

```json
{
  "location": "japaneast",              // Azure リージョン
  "environment": "dev",                 // 環境（dev/staging/prod）
  "projectName": "todomanagement",     // リソース名の接頭辞
  "postgresqlAdminPassword": "..."     // ⚠️ 強力なパスワード必須
}
```

### GitHub Actions Variables（9 個）

```
ACR_NAME
RESOURCE_GROUP
POSTGRES_SERVER
POSTGRES_DB
POSTGRES_USER
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_REDIRECT_URI
API_BASE_URL
```

### GitHub Secrets（1 個）

```
AZURE_CREDENTIALS (Service Principal JSON)
```

---

## 💡 Tips

### 1️⃣ 複数回デプロイする場合

- インフラ（Step 5）は 1 回だけ
- 以降は Step 9 の Git Push から再実行
- 設定変更時は Azure Portal または CLI で直接変更可能

### 2️⃣ 問題が発生した場合

```
以下の順で対応:

1. QUICK_REFERENCE_JAPANESE.md でエラーを検索
2. 対応方法を試す
3. うまくいかない → TROUBLESHOOTING_JAPANESE.md を確認
4. ログを確認（コマンド例あり）
5. それでもダメ → GitHub Issues で報告
```

### 3️⃣ パスワードの管理

- `parameters.json` のパスワードは **Strong**Password (大文字・小文字・数字・記号を含む) が必須
- Azure にデプロイ後は `.env.local` ファイルに記録（Git には含めない）
- 本番環境では Azure Key Vault を使用することをお勧め

### 4️⃣ リソースのクリーンアップ

```powershell
# 全リソース削除（コスト削減）
az group delete --name rg-todomanagement-dev --yes --no-wait

# 約 2～3 分で削除完了
```

---

## 🔗 関連ドキュメント

このフォルダ外にある参考資料：

- **README.md** - プロジェクト概要
- **docs/ARCHITECTURE_GUIDE.md** - システムアーキテクチャ
- **docs/GITHUB_CONFIG_SETUP.md** - GitHub 設定詳細
- **infra/README.md** - Bicep テンプレート詳細
- **src/api/README.md** - API ドキュメント
- **src/web/README.md** - Web フロントエンド ドキュメント

---

## ✅ チェックリスト

デプロイ完了を確認するための最終チェック：

- [ ] Web URL にアクセスできる
- [ ] ログインボタンが表示される
- [ ] Microsoft/Azure AD でログインできる
- [ ] Todo リストが表示される
- [ ] 新しい Todo を作成できる
- [ ] Todo を編集できる
- [ ] Todo を削除できる
- [ ] API ヘルスチェック返す
  ```
  https://[api-url]/health
  ```

すべてチェック出来たら ✅ **デプロイ完了！**

---

## 📞 サポート

### 一般的な質問

- **ドキュメント内に答えがない**?
  → TROUBLESHOOTING_JAPANESE.md を確認

### 技術的な問題

- **具体的なエラーメッセージがある**?
  → TROUBLESHOOTING_JAPANESE.md で検索

### 新しい問題

- **ドキュメントに載っていない問題**?
  → GitHub Issues で報告してください
  → できるだけ詳しいエラーメッセージとログを含めてください

---

## 📝 バージョン情報

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 1.0 | 2026-03-30 | 初版リリース |

---

## 🎓 学習ステップ

このドキュメント以外に学べること：

1. **基礎レベル**
   - Azure CLI の使用方法
   - GitHub Actions の仕組み
   - PowerShell スクリプト

2. **中級レベル**
   - Bicep テンプレートの構造
   - Container Apps の設定
   - PostgreSQL のチューニング

3. **上級レベル**
   - マルチリージョン デプロイ
   - カスタム YAML Workflow
   - Terraform への移行

---

## 🎉 デプロイ完了後

おめでとうございます！🎊

次のステップ：

1. **カスタマイズ**
   - UI/UX の改善
   - ビジネスロジックの追加
   - データベーススキーマの拡張

2. **本番準備**
   - 本番環境での設定
   - バックアップ戦略
   - セキュリティ監査

3. **監視・保守**
   - Azure Monitor の設定
   - ログ分析
   - パフォーマンスチューニング

---

**楽しいデプロイを！🚀**

ご質問やご指摘があれば、GitHub Issues でお聞きします！

---

**作成者**: DevOps チーム  
**最終更新**: 2026-03-30  
**言語**: 日本語 🇯🇵
