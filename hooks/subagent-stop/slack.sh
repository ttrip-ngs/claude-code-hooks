#!/bin/bash

# SubagentStop Hook用Slack通知ラッパー
# サブエージェント完了通知に特化したメッセージ整形

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/config_loader.sh"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

# サブエージェント完了メッセージを作成
create_subagent_message() {
    local task_description="$1"
    local result_summary="$2"
    local working_time="$3"
    
    local env_info=$(get_environment_info)
    local session_info=$(get_session_info)
    
    # サブエージェント特有の情報
    local subagent_info=""
    if [[ -n "$CLAUDE_SUBAGENT_ID" ]]; then
        subagent_info="サブエージェントID：$CLAUDE_SUBAGENT_ID"
    fi
    
    if [[ -n "$CLAUDE_PARENT_SESSION_ID" ]]; then
        subagent_info="$subagent_info
親セッション：$CLAUDE_PARENT_SESSION_ID"
    fi
    
    # 最新のコミット情報（短時間での変更を重視）
    local last_commit=""
    if git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
        last_commit=$(git log -1 --pretty=format:"Commit: %h - %s (%an, %ar)" 2>/dev/null || echo "")
    fi
    
    cat << EOF
🔄 **サブエージェント作業完了**

$env_info

実行時間：${working_time:-"N/A"}

タスク：
${task_description:-"タスク情報が提供されていません"}

実行結果：
${result_summary:-"実行結果の詳細は記録されていません"}

$(if [[ -n "$subagent_info" ]]; then
    echo "$subagent_info"
fi)

$(if [[ -n "$last_commit" ]]; then
    echo "最新のコミット：
$last_commit"
fi)

$session_info
EOF
}

# サブエージェント作業結果の要約を生成
generate_subagent_result_summary() {
    local summary=""
    
    # サブエージェントの実行結果を分析
    if [[ -n "$CLAUDE_TASK_OUTPUT" ]]; then
        summary="タスク実行結果:
$CLAUDE_TASK_OUTPUT"
    fi
    
    # Gitコミットから作業内容を推定（最近の短時間での変更を重視）
    if git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
        local recent_commits=$(git log --oneline -3 --since="30 minutes ago" 2>/dev/null || echo "")
        if [[ -n "$recent_commits" ]]; then
            summary="$summary

最近のコミット（30分以内）:
$recent_commits"
        fi
        
        # 変更されたファイルの一覧（より短い期間で判定）
        local changed_files=$(git diff --name-only HEAD~1 2>/dev/null | head -5)
        if [[ -n "$changed_files" ]]; then
            summary="$summary

変更されたファイル:
$changed_files"
        fi
    fi
    
    # 作業ディレクトリ内の最近作成されたファイル（サブエージェントタスクでの変更を重視）
    local recent_files=$(find . -type f -mmin -30 -not -path './.git/*' 2>/dev/null | head -3)
    if [[ -n "$recent_files" ]]; then
        summary="$summary

最近変更されたファイル（30分以内）:
$recent_files"
    fi
    
    echo "$summary"
}

# サブエージェント作業時間を推定
estimate_subagent_working_time() {
    local start_time="$1"
    local end_time="$2"
    
    # 環境変数からサブエージェント開始時間を取得
    if [[ -n "$CLAUDE_SUBAGENT_START_TIME" ]]; then
        calculate_execution_time "$CLAUDE_SUBAGENT_START_TIME" "$end_time"
    elif [[ -n "$start_time" && -n "$end_time" ]]; then
        calculate_execution_time "$start_time" "$end_time"
    else
        echo "不明"
    fi
}

# JSON入力から停止制御情報を処理
process_stop_control() {
    local json_input="$1"
    
    # JSON入力が提供されている場合、stop_hook_activeを確認
    if [[ -n "$json_input" ]]; then
        local stop_hook_active=$(extract_json_field "$json_input" "stop_hook_active" "false")
        
        # 無限ループを防ぐため、stop_hook_activeがtrueの場合は早期終了
        if [[ "$stop_hook_active" == "true" ]]; then
            log_info "stop_hook_activeがtrueです。無限ループを防ぐため、処理を終了します"
            return 1
        fi
    fi
    
    return 0
}

main() {
    local task_description="$1"
    local result_summary="$2"
    local working_time="$3"
    local session_start_time="$4"
    
    log_info "SubagentStop Hook (Slack) が開始されました"
    
    # JSON入力からの情報取得（stdin経由）
    local json_input=""
    if [[ ! -t 0 ]]; then
        json_input=$(cat)
        
        # 停止制御情報を処理
        if ! process_stop_control "$json_input"; then
            return 0
        fi
        
        # JSON内容から情報を抽出
        local session_id=$(extract_json_field "$json_input" "session_id" "")
        if [[ -n "$session_id" ]]; then
            export CLAUDE_SESSION_ID="$session_id"
        fi
    fi
    
    # 環境変数からの情報補完
    task_description="${task_description:-$CLAUDE_TASK_DESCRIPTION}"
    
    # サブエージェント作業時間の計算
    local end_time=$(date +%s)
    working_time="${working_time:-$(estimate_subagent_working_time "$session_start_time" "$end_time")}"
    
    # サブエージェント作業結果の要約生成（指定されていない場合）
    if [[ -z "$result_summary" ]]; then
        result_summary=$(generate_subagent_result_summary)
    fi
    
    # サブエージェント完了メッセージを作成
    local message=$(create_subagent_message "$task_description" "$result_summary" "$working_time")
    
    # Slack送信（SubagentStop用設定）
    if send_slack_message "subagent-stop" "$message" "$SLACK_CHANNEL"; then
        log_info "SubagentStop Hook (Slack) が正常に完了しました"
    else
        log_error "SubagentStop Hook (Slack) の実行中にエラーが発生しました"
        exit 1
    fi
}

# 使用方法を表示
show_usage() {
    cat << EOF
Usage: $0 [task_description] [result_summary] [working_time] [session_start_time]
       echo '{json}' | $0

Arguments:
  task_description   - タスク説明
  result_summary     - 実行結果要約
  working_time       - 実行時間
  session_start_time - セッション開始時刻（Unix timestamp）

Environment Variables:
  SLACK_WEBHOOK_URL         - Slack Webhook URL (必須)
  SLACK_CHANNEL             - 送信先チャンネル (必須)
  SLACK_ICON                - アイコン (オプション)
  SLACK_USERNAME            - ユーザー名 (オプション)
  CLAUDE_SESSION_ID         - Claude セッションID
  CLAUDE_SUBAGENT_ID        - Claude サブエージェントID
  CLAUDE_TASK_DESCRIPTION   - タスク説明
  CLAUDE_TASK_OUTPUT        - タスク実行結果
  CLAUDE_PARENT_SESSION_ID  - 親セッションID

Examples:
  $0 "ファイル検索タスク" "5個のファイルを発見しました" "15秒"
  echo '{"session_id":"abc123","stop_hook_active":false}' | $0
EOF
}

# 引数チェック
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# メイン処理実行
main "$@"