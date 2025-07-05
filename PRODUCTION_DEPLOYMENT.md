# 🚀 本番環境デプロイメントガイド

開発・本番環境の完全分離による安全なデプロイメント手順

## 📋 概要

このガイドでは、開発用ディレクトリ（`~/dev/claude-code-hocks`）と本番用ディレクトリ（`~/prod/claude-code-hooks-scripts`）を分離し、環境変数の競合を回避する方法を説明します。

## 🔧 解決策：設定ファイルベース管理

### 環境変数競合の回避
- ✅ **設定ファイル**: 各ディレクトリに独立した `.env`
- ✅ **自動環境判定**: ディレクトリパスから環境を自動判定
- ✅ **明示的環境指定**: `CLAUDE_HOOKS_ENV` で環境を強制指定
- ✅ **設定優先順位**: 明示的設定 > プロジェクト設定 > 環境設定 > デフォルト

### 設定読み込み優先順位
1. `$CLAUDE_HOOKS_CONFIG` - 明示的指定ファイル
2. `$PROJECT_ROOT/.env` - プロジェクト直下の設定
3. `$PROJECT_ROOT/config/$ENVIRONMENT.env` - 環境別設定
4. 環境変数
5. デフォルト値

## 🚀 自動デプロイメント（推奨）

### 1. デプロイスクリプトを使用
```bash
# 開発ディレクトリから本番環境にデプロイ
cd ~/dev/claude-code-hocks

# 本番環境にデプロイ
./scripts/deploy.sh production ~/prod/claude-code-hooks-scripts

# ドライラン（確認のみ）
./scripts/deploy.sh --dry-run production ~/prod/claude-code-hooks-scripts
```

### 2. 自動実行される処理
- ✅ 前提条件チェック（git, jq, curl等）
- ✅ 未コミット変更の確認
- ✅ リポジトリクローン
- ✅ 環境設定ファイル作成
- ✅ 権限設定
- ✅ 検証

## 🛠️ 手動デプロイメント

### 1. 本番ディレクトリの作成
```bash
# 本番用ディレクトリに移動/作成
mkdir -p ~/prod
cd ~/prod

# リポジトリをクローン
git clone ~/dev/claude-code-hocks claude-code-hooks-scripts
cd claude-code-hooks-scripts
```

### 2. 本番用設定ファイルの作成
```bash
# 本番用設定テンプレートから設定ファイルを作成
cp config/production.env.template .env

# 設定ファイルを編集
nano .env
```

### 3. 設定ファイルの内容例
```bash
# 本番環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/PROD/WEBHOOK/URL"
SLACK_CHANNEL="UJM1V2AAH"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":robot_face:"
ENVIRONMENT="production"
LOG_LEVEL="info"
```

### 4. 権限設定
```bash
# 設定ファイルの権限を制限
chmod 600 .env

# スクリプトの実行権限確認
chmod +x hooks/*/*.sh
chmod +x lib/*.sh
```

## ⚙️ Claude Code設定

### 本番環境用 settings.toml
```bash
# Claude Code設定ファイルを編集
nano ~/.claude/settings.toml
```

### 設定内容（本番用パス）
```toml
# 本番環境 Claude Code Hooks
[[hooks]]
event = "Stop"
command = "/home/takuyatakaira/prod/claude-code-hooks-scripts/hooks/stop/slack.sh"

[[hooks]]
event = "Notification"
command = "/home/takuyatakaira/prod/claude-code-hooks-scripts/hooks/notification/slack.sh"

[[hooks]]
event = "SubagentStop"
command = "/home/takuyatakaira/prod/claude-code-hooks-scripts/hooks/subagent-stop/slack.sh"
```

## 🧪 環境分離テスト

### 1. 設定確認
```bash
# 開発環境（開発ディレクトリから）
cd ~/dev/claude-code-hocks
./hooks/notification/slack.sh info "開発環境テスト"

# 本番環境（本番ディレクトリから）
cd ~/prod/claude-code-hooks-scripts
./hooks/notification/slack.sh info "本番環境テスト"
```

### 2. 環境自動判定の確認
```bash
# 開発ディレクトリでは自動的に development 環境
cd ~/dev/claude-code-hocks
./hooks/stop/slack.sh "テスト" "開発環境自動判定" "1分"
# → Slack Username: "Claude Code [DEV]"

# 本番ディレクトリでは自動的に production 環境
cd ~/prod/claude-code-hooks-scripts
./hooks/stop/slack.sh "テスト" "本番環境自動判定" "1分"
# → Slack Username: "Claude Code"
```

## 🔄 開発・本番の並行運用

### 開発作業の継続
```bash
# 開発ディレクトリで通常通り作業
cd ~/dev/claude-code-hocks

# 変更をコミット
git add .
git commit -m "新機能追加"

# 本番環境への反映が必要な場合
./scripts/deploy.sh production ~/prod/claude-code-hooks-scripts
```

### 本番環境の独立性
- ✅ **独立した設定**: `.env` ファイルで完全分離
- ✅ **環境自動判定**: ディレクトリパスで自動判定
- ✅ **個別テスト**: 各環境で独立してテスト可能
- ✅ **設定競合なし**: 環境変数の競合が発生しない

## 🛡️ セキュリティ考慮事項

### 1. ファイル権限
```bash
# 設定ファイルの権限制限
chmod 600 .env
chmod 600 config/*.env

# ディレクトリ権限
chmod 755 ~/prod/claude-code-hooks-scripts
```

### 2. 設定ファイル管理
```bash
# 機密情報を含むファイルをGitから除外
echo ".env" >> .gitignore
echo "config/local.env" >> .gitignore
```

### 3. 本番環境での注意事項
- Webhook URLの本番用・開発用の明確な分離
- ログレベルの適切な設定（本番では info, 開発では debug）
- 通知先チャンネルの分離

## 🎯 運用のベストプラクティス

### 1. デプロイフロー
1. 開発環境で機能開発・テスト
2. Git コミット・プッシュ
3. 自動デプロイスクリプト実行
4. 本番環境でテスト実行
5. Claude Code での動作確認

### 2. 設定管理
- 開発環境：デバッグ情報豊富、開発用通知先
- 本番環境：最小限ログ、本番用通知先
- 設定テンプレートでの標準化

### 3. 監視・運用
- 環境ごとの独立したログ管理
- エラー通知の環境別ルーティング
- 定期的な設定同期確認

## ✅ 完了チェックリスト

### デプロイ完了の確認
- [ ] 本番ディレクトリが作成されている
- [ ] `.env` ファイルに本番用設定が記載されている
- [ ] Claude Code 設定が本番パスを指している
- [ ] 本番環境でのテスト実行が成功している
- [ ] 環境自動判定が正しく動作している

### セキュリティ確認
- [ ] `.env` ファイルの権限が 600 に設定されている
- [ ] 本番用 Webhook URL が設定されている
- [ ] 開発・本番で異なる通知先になっている

この手順により、開発・本番環境の完全分離と安全な運用が実現できます！ 🎉