#!/bin/bash

# Stop Hook用Slack通知ラッパー
# 作業完了通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

# 作業完了メッセージを作成
create_stop_message() {
    local instructions="$1"
    local result_summary="$2"
    local working_time="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    # 最新のコミット情報を取得（存在する場合）
    local last_commit=""
    if git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
        last_commit=$(git log -1 --pretty=format:"Commit: %h - %s (%an, %ar)" 2>/dev/null || echo "")
    fi
    
    cat << EOF
✅ **作業完了通知**

$env_info

作業時間：${working_time:-"N/A"}

指示：
${instructions:-"指示情報が提供されていません"}

作業内容：
${result_summary:-"作業結果の詳細は記録されていません"}

$(if [[ -n "$last_commit" ]]; then
    echo "最新のコミット：
$last_commit"
fi)

$session_info
EOF
}

# 作業結果の要約を自動生成
generate_result_summary() {
    local summary=""
    
    # Gitコミットから作業内容を推定
    if git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
        local recent_commits=$(git log --oneline -5 --since="1 hour ago" 2>/dev/null || echo "")
        if [[ -n "$recent_commits" ]]; then
            summary="最近のコミット（1時間以内）:
$recent_commits"
        fi
        
        # 変更されたファイルの一覧
        local changed_files=$(git diff --name-only HEAD~1 2>/dev/null | head -10)
        if [[ -n "$changed_files" ]]; then
            summary="$summary

変更されたファイル:
$changed_files"
        fi
    fi
    
    # 作業ディレクトリ内の最近作成されたファイル
    local recent_files=$(find . -type f -mmin -60 -not -path './.git/*' 2>/dev/null | head -5)
    if [[ -n "$recent_files" ]]; then
        summary="$summary

最近変更されたファイル（1時間以内）:
$recent_files"
    fi
    
    echo "$summary"
}

# 作業時間を推定
estimate_working_time() {
    local start_time="$1"
    local end_time="$2"
    
    # 環境変数からセッション開始時間を取得
    if [[ -n "$CLAUDE_SESSION_START_TIME" ]]; then
        calculate_execution_time "$CLAUDE_SESSION_START_TIME" "$end_time"
    elif [[ -n "$start_time" && -n "$end_time" ]]; then
        calculate_execution_time "$start_time" "$end_time"
    else
        echo "不明"
    fi
}

main() {
    local instructions="$1"
    local result_summary="$2"
    local working_time="$3"
    local session_start_time="$4"
    
    log_info "Stop Hook (Slack) が開始されました"
    
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
    instructions="${instructions:-$CLAUDE_USER_INSTRUCTIONS}"
    
    # 作業時間の計算
    local end_time=$(date +%s)
    working_time="${working_time:-$(estimate_working_time "$session_start_time" "$end_time")}"
    
    # 作業結果の要約生成（指定されていない場合）
    if [[ -z "$result_summary" ]]; then
        result_summary=$(generate_result_summary)
    fi
    
    # 作業完了メッセージを作成
    local message=$(create_stop_message "$instructions" "$result_summary" "$working_time")
    
    # Slack送信（Stop用設定）
    if send_slack_message "stop" "$message" "$SLACK_CHANNEL"; then
        log_info "Stop Hook (Slack) が正常に完了しました"
    else
        log_error "Stop Hook (Slack) の実行中にエラーが発生しました"
        exit 1
    fi
}

# 使用方法を表示
show_usage() {
    cat << EOF
Usage: $0 [instructions] [result_summary] [working_time] [session_start_time]
       echo '{json}' | $0

Arguments:
  instructions      - 作業指示内容
  result_summary    - 作業結果要約
  working_time      - 作業時間
  session_start_time - セッション開始時刻（Unix timestamp）

Environment Variables:
  SLACK_WEBHOOK_URL      - Slack Webhook URL (必須)
  SLACK_CHANNEL          - 送信先チャンネル (必須)
  SLACK_ICON             - アイコン (オプション)
  SLACK_USERNAME         - ユーザー名 (オプション)
  CLAUDE_SESSION_ID      - Claude セッションID
  CLAUDE_USER_INSTRUCTIONS - ユーザー指示内容

Examples:
  $0 "新機能を実装" "機能Aを正常に実装しました" "30分"
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