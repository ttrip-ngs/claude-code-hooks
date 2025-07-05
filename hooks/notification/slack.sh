#!/bin/bash

# Notification Hook用Slack通知ラッパー
# アラート・警告通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/config_loader.sh"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

# 通知メッセージを作成
create_notification_message() {
    local notification_type="$1"  # error, warning, info, success
    local message="$2"
    local context="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    # 通知タイプによるタイトル
    case "$notification_type" in
        "error")
            local title="🚨 **エラーが発生しました**"
            ;;
        "warning")
            local title="⚠️ **警告**"
            ;;
        "success")
            local title="✅ **成功**"
            ;;
        "confirmation")
            local title="❓ **確認が必要です**"
            ;;
        "info"|*)
            local title="ℹ️ **情報**"
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

# 通知タイプの自動判定
detect_notification_type() {
    local message="$1"
    
    # メッセージ内容から通知タイプを推定
    if echo "$message" | grep -i -E "(error|fail|exception|エラー|失敗)" &> /dev/null; then
        echo "error"
    elif echo "$message" | grep -i -E "(warning|warn|注意|警告)" &> /dev/null; then
        echo "warning"
    elif echo "$message" | grep -i -E "(success|complete|完了|成功)" &> /dev/null; then
        echo "success"
    elif echo "$message" | grep -i -E "(confirm|確認|質問|\?)" &> /dev/null; then
        echo "confirmation"
    else
        echo "info"
    fi
}

main() {
    local notification_type="$1"
    local message="$2"
    local context="$3"
    
    log_info "Notification Hook (Slack) が開始されました"
    
    # JSON入力からの情報取得（stdin経由）
    local json_input=""
    if [[ ! -t 0 ]]; then
        json_input=$(cat)
        
        # JSON内容から情報を抽出
        local session_id=$(extract_json_field "$json_input" "session_id" "")
        if [[ -n "$session_id" ]]; then
            export CLAUDE_SESSION_ID="$session_id"
        fi
    fi
    
    # 環境変数からの情報補完
    message="${message:-$CLAUDE_NOTIFICATION}"
    
    # デフォルト値設定
    if [[ -z "$message" ]]; then
        message="通知メッセージが指定されていません"
        notification_type="warning"
    fi
    
    # 通知タイプの自動判定（指定されていない場合）
    if [[ -z "$notification_type" ]]; then
        notification_type=$(detect_notification_type "$message")
        log_info "通知タイプを自動判定しました: $notification_type"
    fi
    
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
        "confirmation")
            options='{"color": "#439FE0", "icon": ":question:"}'
            ;;
        "info")
            options='{"color": "#36a64f", "icon": ":information_source:"}'
            ;;
    esac
    
    # Slack送信（Notification用設定）
    if send_slack_message "notification" "$formatted_message" "$SLACK_CHANNEL" "$options"; then
        log_info "Notification Hook (Slack) が正常に完了しました"
    else
        log_error "Notification Hook (Slack) の実行中にエラーが発生しました"
        exit 1
    fi
}

# 使用方法を表示
show_usage() {
    cat << EOF
Usage: $0 [type] [message] [context]
       echo '{json}' | $0

Arguments:
  type      - 通知タイプ (error, warning, info, success, confirmation)
              省略時は自動判定
  message   - 通知メッセージ
  context   - 追加コンテキスト情報

Environment Variables:
  SLACK_WEBHOOK_URL      - Slack Webhook URL (必須)
  SLACK_CHANNEL          - 送信先チャンネル (必須)
  SLACK_ICON             - アイコン (オプション)
  SLACK_USERNAME         - ユーザー名 (オプション)
  CLAUDE_NOTIFICATION    - Claude 通知内容
  CLAUDE_SESSION_ID      - Claude セッションID

Examples:
  $0 error "ファイルの読み込みに失敗しました"
  $0 warning "メモリ使用量が高くなっています" "現在の使用量: 85%"
  $0 success "テストが正常に完了しました"
  $0 info "処理を開始します"
  echo '{"session_id":"abc123"}' | $0
EOF
}

# 引数チェック
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# メイン処理実行
main "$@"