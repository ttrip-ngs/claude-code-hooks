# Slack通知フック セットアップガイド

Claude Code Hooksの一部として提供されるSlack通知フックの詳細な設定方法を説明します。

## 概要

Slack通知フックは、Claude Codeの作業イベントをSlackチャンネルに自動通知するスクリプトです。

## 前提条件

- Slack Webhook URLの取得（[Slack App設定](https://api.slack.com/apps)から作成）
- jqコマンド（JSON処理用）
- curlコマンド（HTTP通信用）

## セットアップ手順

### 1. 環境設定ファイルの準備

```bash
# プロジェクトディレクトリに移動
cd /path/to/claude-code-hooks

# 環境設定ファイルを作成
cp .env.example .env
```

### 2. Slack Webhook URLの設定

`.env`ファイルを編集して、実際のWebhook URLを設定します：

```bash
# Slack Webhook設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# 通知先チャンネル（オプション）
SLACK_CHANNEL="#your-channel"

# メンション設定（オプション）
SLACK_MENTION_USER="@username"
```

### 3. Claude Code設定ファイルへの登録

`~/.claude/settings.json`に以下の設定を追加：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-code-hooks/hooks/stop/slack.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-code-hooks/hooks/notification/slack.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-code-hooks/hooks/subagent-stop/slack.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. 動作テスト

```bash
# 環境変数を読み込み
source .env

# テスト通知を送信
./hooks/notification/slack.sh info "テストメッセージ"

# 作業完了通知のテスト
./hooks/stop/slack.sh "テスト作業" "正常に完了しました" "1分"
```

## 通知の種類

### 1. 作業完了通知（stop hook）

Claude Codeの作業が完了した際に送信される通知です。

- 作業内容の要約
- 実行時間
- Gitコミット情報
- 変更ファイル一覧（最大3ファイル）

**フォーマット例:**
```
✅ **作業完了通知**
リポジトリ: project-name | ブランチ: feature/xxx
作業時間：15分
指示：通知フォーマットの最適化
作業内容：hooks/notification/slack.sh, hooks/stop/slack.sh | 変更ファイル:file1.sh,file2.sh
最新コミット：abc1234 - 通知フォーマット改善 (user, 5 minutes ago)
```

### 2. 一般通知（notification hook）

エラーや警告など、様々なイベントで送信される通知です。

- info: 情報通知（ℹ️）
- warning: 警告通知（⚠️）
- error: エラー通知（🚨）
- success: 成功通知（✅）
- confirmation: 確認要求（❓）

**フォーマット例:**
```
⚠️ **警告**
リポジトリ: project-name | ブランチ: main
通知内容：設定ファイルが見つかりません | 詳細：.env.exampleを参考に設定してください
```

### 3. サブエージェント完了通知（subagent-stop hook）

サブエージェントの作業が完了した際の通知です。

- 短時間作業に最適化（30分以内のファイル変更検出）
- 親セッション連携機能
- 無限ループ防止機能

## カスタマイズ

### 通知フォーマットの変更

各フックスクリプト内の`send_slack_notification`関数を編集することで、通知フォーマットをカスタマイズできます。

### 環境別設定

開発環境と本番環境で異なる設定を使用する場合：

```bash
# 開発環境
source config/development.env

# 本番環境
source config/production.env
```

## トラブルシューティング

### 通知が届かない場合

1. Webhook URLが正しいか確認
2. 環境変数が正しく設定されているか確認：
   ```bash
   echo $SLACK_WEBHOOK_URL
   ```
3. スクリプトの実行権限を確認：
   ```bash
   chmod +x hooks/**/*.sh
   ```

### エラーメッセージが表示される場合

- `jq: command not found`: jqをインストール（`apt-get install jq` など）
- `curl: command not found`: curlをインストール（`apt-get install curl` など）

## セキュリティ上の注意

- Webhook URLは`.env`ファイルに保存し、絶対にコミットしない
- `.gitignore`に`.env`が含まれていることを確認
- 機密情報が通知に含まれないよう注意

## 関連ドキュメント

- [メインREADME](../README.md)
- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)
