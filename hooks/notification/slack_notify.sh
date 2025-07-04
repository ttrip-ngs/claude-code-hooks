#!/bin/bash

# Claude Code Notification Hook - Slack通知
# 通知イベント発生時にSlackに通知を送信

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib/common" && pwd)"

# 共通ライブラリを読み込み
source "$LIB_DIR/slack_notifier.sh"

# 実行開始時間を記録
START_TIME=$(date +%s)

# 通知メッセージを作成
create_notification_message() {
    local notification_type="$1"
    local notification_content="$2"
    local context="$3"
    
    # 環境情報を取得
    local env_info=$(get_environment_info)
    
    # 現在の時刻を取得
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 通知種別に応じたアイコンとタイトルを設定
    local icon="🔔"
    local title="通知"
    
    case "$notification_type" in
        "error")
            icon="🚨"
            title="エラー通知"
            ;;
        "warning")
            icon="⚠️"
            title="警告通知"
            ;;
        "info")
            icon="ℹ️"
            title="情報通知"
            ;;
        "success")
            icon="✅"
            title="成功通知"
            ;;
        "confirmation")
            icon="❓"
            title="確認要求"
            ;;
    esac
    
    # メッセージを構築
    cat << EOF
$icon **$title**

時刻: $current_time

$env_info

通知内容:
$notification_content

コンテキスト:
$context

---
🤖 Claude Code Notification Hook
EOF
}

# メイン処理
main() {
    local notification_type="${1:-info}"
    local notification_content="${2:-通知が発生しました}"
    local context="${3:-}"
    
    log_info "通知フックが開始されました"
    log_info "通知種別: $notification_type"
    
    # 通知メッセージを作成
    local message=$(create_notification_message "$notification_type" "$notification_content" "$context")
    
    # Slack通知を送信
    send_notifications "notification" "$message"
    
    # 実行時間を計算
    local end_time=$(date +%s)
    local execution_time=$(calculate_execution_time "$START_TIME" "$end_time")
    
    log_info "通知フックが完了しました (実行時間: $execution_time)"
}

# 引数の処理
if [[ $# -eq 0 ]]; then
    # 標準入力からの入力を処理
    if [[ -t 0 ]]; then
        # 対話モードの場合
        echo "通知種別を入力してください (error/warning/info/success/confirmation): "
        read -r notification_type
        echo "通知内容を入力してください: "
        read -r notification_content
        echo "コンテキスト情報を入力してください (オプション): "
        read -r context
    else
        # パイプからの入力を処理
        notification_content=$(cat)
        notification_type="info"
        context=""
    fi
else
    # コマンドライン引数から処理
    notification_type="$1"
    notification_content="$2"
    context="$3"
fi

# メイン処理を実行
main "$notification_type" "$notification_content" "$context"