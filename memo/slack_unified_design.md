# Slack通知 統一設計案

## 🎯 設計方針

**共通処理 + オプション対応 + Hook別ラッパー**の3層構造で、保守性と柔軟性を両立します。

## 🏗️ アーキテクチャ

```
hooks/
├── notification/
│   └── slack.sh          # Notificationイベント用ラッパー
├── stop/
│   └── slack.sh          # Stopイベント用ラッパー
├── subagent-stop/
│   └── slack.sh          # SubagentStopイベント用ラッパー
└── pre-tool-use/
    └── slack.sh          # PreToolUseイベント用ラッパー

lib/
└── slack_messenger.sh    # 共通Slack送信処理
```

## 📝 共通ライブラリ設計

### `lib/slack_messenger.sh` - 核となる共通処理
```bash
#!/bin/bash

# Slack通知の共通ライブラリ
# 全Hook種別で使用される統一されたSlack送信機能

send_slack_message() {
    local message_type="$1"     # notification, stop, subagent-stop, etc.
    local message="$2"          # メッセージ本文
    local channel="${3:-$SLACK_CHANNEL}"
    local options="$4"          # 追加オプション（JSON形式）
    
    # Hook種別ごとのデフォルト設定
    case "$message_type" in
        "notification")
            local default_icon=":warning:"
            local default_username="Claude Code Alert"
            local color="warning"
            ;;
        "stop")
            local default_icon=":white_check_mark:"
            local default_username="Claude Code"
            local color="good"
            ;;
        "subagent-stop")
            local default_icon=":arrows_counterclockwise:"
            local default_username="Claude Code Subagent"
            local color="#36a64f"
            ;;
        "pre-tool-use")
            local default_icon=":gear:"
            local default_username="Claude Code Pre-check"
            local color="#439FE0"
            ;;
        *)
            local default_icon=":robot_face:"
            local default_username="Claude Code"
            local color="#666666"
            ;;
    esac
    
    # オプションからの上書き設定を解析
    local icon="${SLACK_ICON:-$default_icon}"
    local username="${SLACK_USERNAME:-$default_username}"
    
    if [[ -n "$options" ]]; then
        icon=$(echo "$options" | jq -r '.icon // "'"$icon"'"' 2>/dev/null || echo "$icon")
        username=$(echo "$options" | jq -r '.username // "'"$username"'"' 2>/dev/null || echo "$username")
        color=$(echo "$options" | jq -r '.color // "'"$color"'"' 2>/dev/null || echo "$color")
    fi
    
    # メッセージペイロード構築
    local payload=$(jq -n \
        --arg channel "$channel" \
        --arg text "$message" \
        --arg username "$username" \
        --arg icon "$icon" \
        --arg color "$color" \
        '{
            channel: $channel,
            text: $text,
            username: $username,
            icon_emoji: $icon,
            attachments: [
                {
                    color: $color,
                    text: $text,
                    mrkdwn_in: ["text"]
                }
            ]
        }')
    
    # Webhook送信
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$SLACK_WEBHOOK_URL"
}

# 環境情報取得（共通）
get_environment_info() {
    local repo_name=""
    local branch_name=""
    
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        repo_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")
        branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")
    fi
    
    echo "リポジトリ：${repo_name:-N/A}
ブランチ：${branch_name:-N/A}"
}

# セッション情報取得（共通）
get_session_info() {
    echo "セッション：${CLAUDE_SESSION_ID:-N/A}
作業時刻：$(date '+%Y-%m-%d %H:%M:%S')"
}
```

## 📁 Hook別ラッパースクリプト

### `hooks/stop/slack.sh` - Stop専用ラッパー
```bash
#!/bin/bash

# Stop Hook用Slack通知ラッパー
# 作業完了通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

create_stop_message() {
    local instructions="$1"
    local result_summary="$2"
    local working_time="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    cat << EOF
✅ **作業完了通知**

$env_info

作業時間：${working_time:-"N/A"}

指示：
${instructions:-"指示情報が提供されていません"}

作業内容：
${result_summary:-"作業結果の詳細は記録されていません"}

$session_info
EOF
}

main() {
    local instructions="$1"
    local result_summary="$2"
    local working_time="$3"
    
    # JSON入力からの情報取得（stdin経由）
    local json_input=""
    if [[ ! -t 0 ]]; then
        json_input=$(cat)
    fi
    
    # 環境変数からの情報補完
    instructions="${instructions:-$CLAUDE_USER_INSTRUCTIONS}"
    
    # 作業完了メッセージを作成
    local message=$(create_stop_message "$instructions" "$result_summary" "$working_time")
    
    # Slack送信（Stop用設定）
    send_slack_message "stop" "$message" "$SLACK_CHANNEL"
}

# 引数チェック
if [[ $# -eq 0 && -t 0 ]]; then
    echo "Usage: $0 [instructions] [result_summary] [working_time]"
    echo "Or: echo '{json}' | $0"
    exit 1
fi

main "$@"
```

### `hooks/notification/slack.sh` - Notification専用ラッパー
```bash
#!/bin/bash

# Notification Hook用Slack通知ラッパー
# アラート・警告通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

create_notification_message() {
    local notification_type="$1"  # error, warning, info, success
    local message="$2"
    local context="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    # 通知タイプによるアイコンとタイトル
    case "$notification_type" in
        "error")
            local title="🚨 **エラーが発生しました**"
            local color="danger"
            ;;
        "warning")
            local title="⚠️ **警告**"
            local color="warning"
            ;;
        "success")
            local title="✅ **成功**"
            local color="good"
            ;;
        "info"|*)
            local title="ℹ️ **情報**"
            local color="#439FE0"
            ;;
    esac
    
    cat << EOF
$title

$env_info

通知内容：
$message

$(if [[ -n "$context" ]]; then
    echo "詳細：
$context"
fi)

$session_info
EOF
}

main() {
    local notification_type="$1"
    local message="$2"
    local context="$3"
    
    # JSON入力からの情報取得
    local json_input=""
    if [[ ! -t 0 ]]; then
        json_input=$(cat)
        # JSON内容からメッセージを抽出（環境変数が優先）
        message="${message:-$CLAUDE_NOTIFICATION}"
    fi
    
    # デフォルト値設定
    notification_type="${notification_type:-info}"
    message="${message:-"通知メッセージが指定されていません"}"
    
    # 通知メッセージを作成
    local formatted_message=$(create_notification_message "$notification_type" "$message" "$context")
    
    # 追加オプション（通知タイプに応じたカスタマイズ）
    local options=""
    case "$notification_type" in
        "error")
            options='{"color": "danger", "icon": ":exclamation:"}'
            ;;
        "warning")
            options='{"color": "warning", "icon": ":warning:"}'
            ;;
        "success")
            options='{"color": "good", "icon": ":white_check_mark:"}'
            ;;
    esac
    
    # Slack送信（Notification用設定）
    send_slack_message "notification" "$formatted_message" "$SLACK_CHANNEL" "$options"
}

# 引数チェック
if [[ $# -eq 0 && -t 0 ]]; then
    echo "Usage: $0 [type] [message] [context]"
    echo "Types: error, warning, info, success"
    echo "Or: echo '{json}' | $0"
    exit 1
fi

main "$@"
```

### `hooks/subagent-stop/slack.sh` - SubagentStop専用ラッパー
```bash
#!/bin/bash

# SubagentStop Hook用Slack通知ラッパー
# サブエージェント完了通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

create_subagent_message() {
    local task_description="$1"
    local result_summary="$2"
    local working_time="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    cat << EOF
🔄 **サブエージェント作業完了**

$env_info

実行時間：${working_time:-"N/A"}

タスク：
${task_description:-"タスク情報が提供されていません"}

実行結果：
${result_summary:-"実行結果の詳細は記録されていません"}

$session_info
EOF
}

main() {
    local task_description="$1"
    local result_summary="$2"
    local working_time="$3"
    
    # JSON入力からの情報取得
    local json_input=""
    if [[ ! -t 0 ]]; then
        json_input=$(cat)
    fi
    
    # 環境変数からの情報補完
    task_description="${task_description:-$CLAUDE_TASK_DESCRIPTION}"
    result_summary="${result_summary:-$CLAUDE_TASK_OUTPUT}"
    
    # サブエージェント完了メッセージを作成
    local message=$(create_subagent_message "$task_description" "$result_summary" "$working_time")
    
    # Slack送信（SubagentStop用設定）
    send_slack_message "subagent-stop" "$message" "$SLACK_CHANNEL"
}

# 引数チェック
if [[ $# -eq 0 && -t 0 ]]; then
    echo "Usage: $0 [task_description] [result_summary] [working_time]"
    echo "Or: echo '{json}' | $0"
    exit 1
fi

main "$@"
```

## ⚙️ 設定例

### 環境変数設定
```bash
# 基本設定
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_CHANNEL="UJM1V2AAH"

# オプション設定（省略可能）
export SLACK_ICON=":robot_face:"
export SLACK_USERNAME="Claude Code Custom"
```

### Claude Code設定例
```toml
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack.sh"

[[hooks]]
event = "Notification"
command = "/path/to/claude-code-hooks-scripts/hooks/notification/slack.sh"

[[hooks]]
event = "SubagentStop"
command = "/path/to/claude-code-hooks-scripts/hooks/subagent-stop/slack.sh"
```

## 🎯 利点

1. **共通処理の活用**: Slack送信ロジックの重複排除
2. **Hook特化**: 各Hookに最適化されたメッセージ形式
3. **柔軟性**: オプションによるカスタマイズ
4. **簡単設定**: 環境変数による一元管理
5. **保守性**: 機能分離により修正影響範囲が明確

この設計により、Slack通知の共通処理を活用しつつ、各Hookの特性に応じた最適なメッセージ配信が実現できます。