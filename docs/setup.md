# Claude Code Hooks Scripts セットアップガイド

## 概要
Claude Code Hooks Scriptsを使用してSlack通知機能を設定する手順を説明します。

## 前提条件
- `jq` コマンドがインストールされていること
- `curl` コマンドがインストールされていること
- SlackのWebhook URLが取得済みであること

### 必要パッケージのインストール
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install jq curl

# macOS (Homebrew)
brew install jq curl
```

## セットアップ手順

### 1. 自動セットアップ（推奨）
```bash
cd /path/to/claude-code-hooks-scripts
./config/setup.sh
```

セットアップスクリプトが以下を自動実行します：
- 設定ディレクトリの作成 (`$HOME/.config/claude-code-hooks-scripts/`)
- 設定ファイル例の選択とコピー
- 適切な権限設定

### 2. 手動セットアップ
```bash
# 設定ディレクトリの作成
mkdir -p "$HOME/.config/claude-code-hooks-scripts"

# 設定ファイルをコピー
cp config/examples/minimal-config.json "$HOME/.config/claude-code-hooks-scripts/config.json"

# 権限設定
chmod 600 "$HOME/.config/claude-code-hooks-scripts/config.json"
```

## 設定ファイルの編集

### 基本設定
```bash
nano "$HOME/.config/claude-code-hooks-scripts/config.json"
```

以下の部分を実際の値に変更：
```json
{
  "hooks": {
    "notification": {
      "slack_notifications": [
        {
          "channel": "#your-channel",
          "webhook_url": "https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK_URL",
          "enabled": true
        }
      ]
    },
    "stop": {
      "slack_notifications": [
        {
          "channel": "@your-username",
          "webhook_url": "https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK_URL",
          "enabled": true
        }
      ]
    },
    "subagent_stop": {
      "slack_notifications": [
        {
          "channel": "@your-username",
          "webhook_url": "https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK_URL",
          "enabled": true
        }
      ]
    }
  }
}
```

### Webhook URLの取得方法
1. Slackワークスペースの管理画面にアクセス
2. 「アプリ」→「Incoming Webhooks」を選択
3. 新しいWebhookを作成し、URLをコピー

## テスト実行

### 設定テスト
```bash
cd /path/to/claude-code-hooks-scripts
export CLAUDE_HOOKS_CONFIG="$HOME/.config/claude-code-hooks-scripts/config.json"
./test_notifications.sh
```

### 個別テスト
```bash
# Notification Hook
./hooks/notification/slack_notify.sh "info" "テストメッセージ"

# Stop Hook  
./hooks/stop/slack_notify.sh "テスト作業" "テスト結果"

# SubagentStop Hook
./hooks/subagent-stop/slack_notify.sh "テストタスク" "サブエージェントテスト結果"
```

## Claude Codeでの設定

### hooksの有効化
Claude Codeの設定ファイルでhooksを指定：

```json
{
  "hooks": {
    "notification": "/path/to/claude-code-hooks-scripts/hooks/notification/slack_notify.sh",
    "stop": "/path/to/claude-code-hooks-scripts/hooks/stop/slack_notify.sh",
    "subagent_stop": "/path/to/claude-code-hooks-scripts/hooks/subagent-stop/slack_notify.sh"
  }
}
```

## トラブルシューティング

### よくある問題

#### 1. 設定ファイルが見つからない
```bash
ls -la "$HOME/.config/claude-code-hooks-scripts/config.json"
```
ファイルが存在しない場合はセットアップを再実行してください。

#### 2. 権限エラー
```bash
chmod 600 "$HOME/.config/claude-code-hooks-scripts/config.json"
```

#### 3. jqコマンドエラー
```bash
# 設定ファイルの構文チェック
jq '.' "$HOME/.config/claude-code-hooks-scripts/config.json"
```

#### 4. Webhook URLの検証
```bash
# 設定確認
jq '.hooks.notification.slack_notifications[0].webhook_url' "$HOME/.config/claude-code-hooks-scripts/config.json"

# 手動テスト
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"テストメッセージ"}' \
  YOUR_WEBHOOK_URL
```

## 設定ファイルの場所

### デフォルトパス
- **設定ファイル**: `$HOME/.config/claude-code-hooks-scripts/config.json`
- **設定ディレクトリ**: `$HOME/.config/claude-code-hooks-scripts/`

### カスタムパス
環境変数で設定ファイルパスをカスタマイズ可能：
```bash
export CLAUDE_HOOKS_CONFIG="/custom/path/to/config.json"
```

### XDG Base Directory対応
`XDG_CONFIG_HOME` 環境変数も考慮されます：
```bash
export XDG_CONFIG_HOME="/custom/config/dir"
# 設定ファイルパス: /custom/config/dir/claude-code-hooks-scripts/config.json
```

## セキュリティ注意事項

1. **設定ファイルの権限**: 600 (所有者のみ読み書き可能)
2. **Webhook URLの管理**: GitやDockerイメージに含めない
3. **ログファイル**: Webhook URLがログに出力されないよう注意