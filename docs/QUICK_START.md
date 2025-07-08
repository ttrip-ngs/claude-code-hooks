# Claude Code Hooks クイックスタート

最短5分でClaude Code HooksのSlack通知スクリプトをセットアップできます。

## 1. 準備（1分）

```bash
# プロジェクトをクローン
git clone https://github.com/ttrip-ngs/claude-code-hooks.git
cd claude-code-hooks

# 依存関係チェック（jq, curl, gitが必要）
source examples/environment-setup.sh
```

## 2. 環境設定（2分）

```bash
# 環境設定ファイルを作成
cp .env.example .env

# .envファイルを編集（エディタで開いて実際の値を設定）
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK/URL"
# SLACK_CHANNEL="#your-channel"

# 環境変数を読み込み
source .env
```

## 3. Claude Code設定（1分）

```bash
# 設定ディレクトリ作成
mkdir -p ~/.claude

# 設定ファイル作成
cat > ~/.claude/settings.toml << EOF
# Stop Hook: 作業完了時の通知
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks/hooks/stop/slack.sh"

# Notification Hook: 各種通知
[[hooks]]
event = "Notification"
command = "/path/to/claude-code-hooks/hooks/notification/slack.sh"

# SubagentStop Hook: サブエージェント完了時の通知
[[hooks]]
event = "SubagentStop"
command = "/path/to/claude-code-hooks/hooks/subagent-stop/slack.sh"
EOF
```

## 4. テスト実行（1分）

```bash
# テスト通知を送信
./hooks/notification/slack.sh info "Claude Code Hooks テスト完了！"

# 作業完了通知テスト
./hooks/stop/slack.sh "セットアップ作業" "Claude Code Hooks が正常に設定されました" "5分"
```

## 5. 動作確認

Claude Codeで何らかの作業を実行すると、自動的にSlack通知が送信されます！

---

- **より詳細な設定**: [SETUP_GUIDE.md](SETUP_GUIDE.md)を参照
- **トラブルシューティング**: [SETUP_GUIDE.md#トラブルシューティング](SETUP_GUIDE.md#トラブルシューティング)を確認
- **他のフックスクリプト**: [README.md](../README.md)で最新情報を確認
