# Claude Code Hooks 設定リファレンス

Claude Code Hooksのスクリプト集に含まれる各種設定オプションの詳細を説明します。

## 環境変数

Slack通知スクリプトで使用される環境変数：

### 必須設定

| 環境変数 | 説明 | 例 |
|---------|------|-----|
| `SLACK_WEBHOOK_URL` | Slack Incoming Webhook URL | `https://hooks.slack.com/services/YOUR/WEBHOOK/URL` |

### オプション設定

| 環境変数 | 説明 | デフォルト値 |
|---------|------|-------------|
| `SLACK_CHANNEL` | 通知先チャンネル | Webhook設定のデフォルト |
| `SLACK_USERNAME` | Bot表示名 | `Claude Code` |
| `SLACK_ICON` | Botアイコン | `:robot_face:` |
| `SLACK_MENTION_USER` | メンション対象 | なし |
| `SLACK_COLOR_SUCCESS` | 成功時の色 | `good` (緑) |
| `SLACK_COLOR_ERROR` | エラー時の色 | `danger` (赤) |
| `SLACK_COLOR_INFO` | 情報時の色 | `#3AA3E3` (青) |

## 環境変数の設定方法

### 1. 一時的な設定（現在のセッションのみ）

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_CHANNEL="#dev-notifications"
```

### 2. .envファイルを使用（推奨）

```bash
# .envファイルを作成
cp .env.example .env

# .envファイルを編集
nano .env

# 環境変数を読み込み
source .env
```

### 3. 永続的な設定（シェル設定ファイル）

```bash
# ~/.bashrcまたは~/.zshrcに追加
echo 'export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"' >> ~/.bashrc
echo 'export SLACK_CHANNEL="#dev-notifications"' >> ~/.bashrc

# 設定を再読み込み
source ~/.bashrc
```

## Claude Code設定ファイル

### settings.toml形式

`~/.claude/settings.toml`に以下の形式で設定：

```toml
# フックイベントごとの設定
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks/hooks/stop/slack.sh"

[[hooks]]
event = "Notification"
command = "/path/to/claude-code-hooks/hooks/notification/slack.sh"

[[hooks]]
event = "SubagentStop"
command = "/path/to/claude-code-hooks/hooks/subagent-stop/slack.sh"

# 条件付き実行の例
[[hooks]]
event = "PostToolUse"
matcher = "Edit|Write"
command = "/path/to/custom-hook.sh"

# バックグラウンド実行の例
[[hooks]]
event = "Stop"
command = "/path/to/background-task.sh"
run_in_background = true
```

### 利用可能なイベント

| イベント | 説明 |
|---------|------|
| `Stop` | Claude Codeセッション終了時 |
| `Notification` | 通知イベント発生時 |
| `SubagentStop` | サブエージェント（Task tool）終了時 |
| `PreToolUse` | ツール使用前 |
| `PostToolUse` | ツール使用後 |

## セキュリティベストプラクティス

### 1. 機密情報の管理

- Webhook URLは環境変数または.envファイルで管理
- .envファイルは必ず.gitignoreに追加
- 設定ファイルの権限を制限：

```bash
chmod 600 .env
chmod 600 ~/.claude/settings.toml
```

### 2. Git管理から除外

`.gitignore`に以下を追加：

```
.env
.env.local
*.webhook
config/local/*
```

### 3. 環境別設定

開発環境と本番環境で異なる設定を使用：

```bash
# 開発環境
source config/development.env

# 本番環境
source config/production.env
```

## カスタマイズ例

### 1. 複数チャンネルへの通知

環境変数で複数の通知先を設定：

```bash
# エラー通知用
export SLACK_ERROR_CHANNEL="#errors"
export SLACK_ERROR_WEBHOOK_URL="https://hooks.slack.com/services/ERROR/WEBHOOK"

# 進捗通知用
export SLACK_PROGRESS_CHANNEL="#progress"
export SLACK_PROGRESS_WEBHOOK_URL="https://hooks.slack.com/services/PROGRESS/WEBHOOK"
```

### 2. 条件付き通知

スクリプト内で条件分岐を実装：

```bash
# 作業時間が長い場合のみ通知
if [ $DURATION -gt 300 ]; then
    send_slack_notification "長時間作業が完了しました"
fi
```

### 3. カスタムフォーマット

Slack通知のフォーマットをカスタマイズ：

```bash
# リッチなメッセージフォーマット
{
    "attachments": [{
        "color": "good",
        "title": "作業完了",
        "fields": [
            {"title": "タスク", "value": "$TASK_NAME", "short": true},
            {"title": "実行時間", "value": "$DURATION", "short": true}
        ],
        "footer": "Claude Code Hooks",
        "ts": $(date +%s)
    }]
}
```

## トラブルシューティング

### 環境変数が認識されない

```bash
# 環境変数の確認
echo $SLACK_WEBHOOK_URL

# 環境変数の再読み込み
source .env
```

### 権限エラー

```bash
# スクリプトに実行権限を付与
chmod +x hooks/**/*.sh
```

### Webhook URLの検証

```bash
# curlで直接テスト
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"テストメッセージ"}' \
  "$SLACK_WEBHOOK_URL"
```

## 関連ドキュメント

- [README](../README.md) - プロジェクト概要
- [QUICK_START.md](QUICK_START.md) - クイックスタートガイド
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - 詳細セットアップガイド
- [slack-notification-setup.md](slack-notification-setup.md) - Slack通知専用ガイド
