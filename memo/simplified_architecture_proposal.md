# Claude Code Hooks Scripts - シンプル化アーキテクチャ提案

## 🎯 **設計方針の転換**

Claude Code側で複数Hook登録が可能であることを踏まえ、このプロジェクトは**単一Hook用スクリプトの集合体**として、よりシンプルで保守しやすい構造に変更します。

## 📊 **現在の問題点**

### ❌ 複雑すぎる現在の設計
- プロセッサー機構の提案は過度に複雑
- 1つのスクリプト内での複数処理統合
- 設定ファイルが複雑化（`slack_notifications[]`配列）
- 共通ライブラリがSlack特化

### ✅ 目指すべきシンプルな構造
- **1Hook = 1スクリプト = 1責任**
- **独立したスクリプト集合**
- **最小限の依存関係**
- **再利用可能なコンポーネント**

## 🏗️ **新しいシンプルなアーキテクチャ**

### ディレクトリ構成（シンプル版）
```
claude-code-hooks-scripts/
├── hooks/
│   ├── notification/
│   │   ├── slack.sh                 # Slack通知専用
│   │   ├── email.sh                 # メール通知専用
│   │   ├── discord.sh               # Discord通知専用
│   │   └── webhook.sh               # 汎用Webhook専用
│   ├── stop/
│   │   ├── slack_completion.sh      # 作業完了Slack通知
│   │   ├── email_report.sh          # メールレポート送信
│   │   ├── git_autocommit.sh        # Git自動コミット
│   │   ├── cleanup_temp.sh          # 一時ファイル削除
│   │   └── log_session.sh           # セッションログ記録
│   ├── subagent-stop/
│   │   ├── slack_subtask.sh         # サブタスク完了通知
│   │   ├── progress_log.sh          # 進捗ログ
│   │   └── metrics_collect.sh       # メトリクス収集
│   ├── pre-tool-use/
│   │   ├── security_check.sh        # セキュリティチェック
│   │   ├── backup_files.sh          # ファイルバックアップ
│   │   └── validate_permissions.sh  # 権限検証
│   └── post-tool-use/
│       ├── auto_format.sh           # 自動フォーマット
│       ├── run_tests.sh             # テスト実行
│       ├── lint_check.sh            # Lint実行
│       └── git_add.sh               # Git自動追加
├── lib/
│   ├── slack.sh                     # Slack操作関数
│   ├── email.sh                     # メール操作関数
│   ├── git.sh                       # Git操作関数
│   ├── file.sh                      # ファイル操作関数
│   └── common.sh                    # 共通ユーティリティ
├── config/
│   ├── slack-config.env             # Slack設定例
│   ├── email-config.env             # メール設定例
│   └── git-config.env               # Git設定例
└── examples/
    ├── claude-settings.toml          # Claude Code設定例
    └── usage-examples.md             # 使用例
```

## 📝 **使用方法（シンプル版）**

### Claude Code設定例
```toml
# 複数のスクリプトを独立して登録
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack_completion.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/git_autocommit.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/cleanup_temp.sh"

[[hooks]]
event = "Notification"
command = "/path/to/claude-code-hooks-scripts/hooks/notification/slack.sh"

[[hooks]]
event = "PostToolUse"
matcher = "Edit|Write"
command = "/path/to/claude-code-hooks-scripts/hooks/post-tool-use/auto_format.sh"
```

### 個別スクリプトの設定
```bash
# 環境変数による設定（各スクリプト独立）
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
export SLACK_CHANNEL="UJM1V2AAH"

# 直接実行も可能
./hooks/stop/slack_completion.sh "作業完了"
./hooks/notification/slack.sh "通知メッセージ"
```

## 🔧 **実装方針**

### 1. 各スクリプトの独立性
```bash
#!/bin/bash
# hooks/stop/slack_completion.sh

# 最小限の依存関係
source "$(dirname "$0")/../../lib/slack.sh"
source "$(dirname "$0")/../../lib/common.sh"

# 単一責任：Slack作業完了通知のみ
main() {
    local message="$1"
    send_slack_message "$SLACK_CHANNEL" "$message"
}

# 引数またはstdin両方対応
if [[ $# -gt 0 ]]; then
    main "$@"
else
    main "$(cat)"
fi
```

### 2. 共通ライブラリの細分化
```bash
# lib/slack.sh - Slack操作のみ
send_slack_message() {
    local channel="$1"
    local message="$2"
    # Slack送信ロジック
}

# lib/common.sh - 汎用ユーティリティ
log_info() { echo "[INFO] $(date) $1" >&2; }
get_session_info() { echo "$CLAUDE_SESSION_ID"; }
```

### 3. 設定の分離
```bash
# config/slack-config.env
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
SLACK_DEFAULT_CHANNEL="UJM1V2AAH"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":robot_face:"
```

## 💡 **利点**

### 1. **シンプルさ**
- 1スクリプト = 1機能
- 理解しやすい構造
- デバッグが容易

### 2. **柔軟性**
- 必要な機能だけ選択可能
- Claude Code側で自由に組み合わせ
- 独立した保守・更新

### 3. **拡張性**
- 新しいスクリプトの追加が簡単
- 既存スクリプトに影響なし
- 段階的な機能追加

### 4. **再利用性**
- 他のプロジェクトでも利用可能
- スクリプト単体でのテスト
- 異なる環境での部分利用

## 🔄 **移行計画**

### Phase 1: 既存スクリプトの分離
1. `hooks/stop/slack_notify.sh` を `hooks/stop/slack_completion.sh` に簡素化
2. `hooks/notification/slack_notify.sh` を `hooks/notification/slack.sh` に簡素化
3. 共通ライブラリの細分化

### Phase 2: 新しいスクリプトの追加
1. `hooks/stop/git_autocommit.sh`
2. `hooks/stop/cleanup_temp.sh`
3. `hooks/post-tool-use/auto_format.sh`

### Phase 3: ドキュメント整備
1. シンプルな使用例の作成
2. Claude Code設定例の提供
3. 個別スクリプトの説明

## 🎯 **目標**

**「Claude Code Hooks用スクリプトのコレクション」**として、以下を実現：

1. **Pick & Choose**: 必要な機能だけ選択
2. **Plug & Play**: すぐに使える独立スクリプト
3. **Simple & Clear**: 1つの責任、明確な機能
4. **Maintainable**: 保守しやすい構造

この方針により、複雑なプロセッサー機構は不要となり、Claude Code Hooksの並列実行機能を最大限活用できます。