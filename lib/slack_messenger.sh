#!/bin/bash

# Slack通知の共通ライブラリ
# 全Hook種別で使用される統一されたSlack送信機能

# ログ出力関数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

# Slack通知の統一送信関数
send_slack_message() {
    local message_type="$1"     # notification, stop, subagent-stop, etc.
    local message="$2"          # メッセージ本文
    local channel="${3:-$SLACK_CHANNEL}"
    local options="$4"          # 追加オプション（JSON形式）
    
    # 必須環境変数チェック
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        log_error "SLACK_WEBHOOK_URL環境変数が設定されていません"
        return 1
    fi
    
    if [[ -z "$channel" ]]; then
        log_error "Slackチャンネルが指定されていません（SLACK_CHANNEL環境変数またはパラメータで指定）"
        return 1
    fi
    
    # Hook種別ごとのデフォルト設定
    case "$message_type" in
        "notification")
            local default_icon=":warning:"
            local default_username="Claude Code Alert"
            local default_color="warning"
            ;;
        "stop")
            local default_icon=":white_check_mark:"
            local default_username="Claude Code"
            local default_color="good"
            ;;
        "subagent-stop")
            local default_icon=":arrows_counterclockwise:"
            local default_username="Claude Code Subagent"
            local default_color="#36a64f"
            ;;
        "pre-tool-use")
            local default_icon=":gear:"
            local default_username="Claude Code Pre-check"
            local default_color="#439FE0"
            ;;
        "post-tool-use")
            local default_icon=":hammer_and_wrench:"
            local default_username="Claude Code Post-process"
            local default_color="#7CD197"
            ;;
        *)
            local default_icon=":robot_face:"
            local default_username="Claude Code"
            local default_color="#666666"
            ;;
    esac
    
    # オプションからの上書き設定を解析
    local icon="${SLACK_ICON:-$default_icon}"
    local username="${SLACK_USERNAME:-$default_username}"
    local color="$default_color"
    
    if [[ -n "$options" ]] && command -v jq &> /dev/null; then
        icon=$(echo "$options" | jq -r '.icon // "'"$icon"'"' 2>/dev/null || echo "$icon")
        username=$(echo "$options" | jq -r '.username // "'"$username"'"' 2>/dev/null || echo "$username")
        color=$(echo "$options" | jq -r '.color // "'"$color"'"' 2>/dev/null || echo "$color")
    fi
    
    # curlコマンドの存在チェック
    if ! command -v curl &> /dev/null; then
        log_error "curlコマンドが見つかりません"
        return 1
    fi
    
    # メッセージペイロード構築
    local payload=""
    if command -v jq &> /dev/null; then
        # jqが利用可能な場合：構造化されたメッセージ
        payload=$(jq -n \
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
    else
        # jqが利用できない場合：シンプルなメッセージ
        log_info "jqコマンドが利用できません。シンプルなメッセージ形式で送信します"
        payload="{\"channel\":\"$channel\",\"text\":\"$message\",\"username\":\"$username\",\"icon_emoji\":\"$icon\"}"
    fi
    
    # Webhook送信
    log_info "Slack通知を送信中: $channel ($message_type)"
    
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$SLACK_WEBHOOK_URL")
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        log_info "Slack通知を送信しました: $channel"
        return 0
    else
        log_error "Slack通知の送信に失敗しました: HTTP $http_code"
        log_error "Response: $response_body"
        return 1
    fi
}

# 環境情報取得（共通）
get_environment_info() {
    local repo_name=""
    local branch_name=""
    
    if git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
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

# 実行時間計算（共通）
calculate_execution_time() {
    local start_time="$1"
    local end_time="$2"
    
    if [[ -z "$start_time" || -z "$end_time" ]]; then
        echo "不明"
        return
    fi
    
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 60 ]]; then
        echo "${duration}秒"
    elif [[ $duration -lt 3600 ]]; then
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))
        echo "${minutes}分${seconds}秒"
    else
        local hours=$((duration / 3600))
        local minutes=$(((duration % 3600) / 60))
        echo "${hours}時間${minutes}分"
    fi
}

# JSON入力からのデータ抽出（共通）
extract_json_field() {
    local json_input="$1"
    local field="$2"
    local default_value="$3"
    
    if [[ -n "$json_input" ]] && command -v jq &> /dev/null; then
        echo "$json_input" | jq -r ".$field // \"$default_value\"" 2>/dev/null || echo "$default_value"
    else
        echo "$default_value"
    fi
}