#!/bin/bash

# Claude Code SubagentStop Hook - Slack通知
# Claude Code subagent（Task tool）応答終了時にSlackに作業完了通知を送信

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib/common" && pwd)"

# 共通ライブラリを読み込み
source "$LIB_DIR/slack_notifier.sh"

# 実行開始時間を記録
START_TIME=$(date +%s)

# サブエージェント作業完了メッセージを作成
create_subagent_completion_message() {
    local session_info="$1"
    local working_time="$2"
    local task_description="$3"
    local result_summary="$4"
    local subagent_context="$5"
    
    # 環境情報を取得
    local env_info=$(get_environment_info)
    
    # 現在の時刻を取得
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 最後のコミット情報を取得（存在する場合）
    local last_commit=""
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        last_commit=$(git log -1 --pretty=format:"Commit: %h - %s (%an, %ar)" 2>/dev/null || echo "")
    fi
    
    # メッセージを構築
    cat << EOF
🔄 **サブエージェント作業完了通知**

完了時刻: $current_time

$env_info

作業時間: ${working_time:-"N/A"}

タスク内容:
${task_description:-"タスク情報が提供されていません"}

サブエージェント実行結果:
${result_summary:-"作業結果の詳細は記録されていません"}

サブエージェントコンテキスト:
${subagent_context:-"コンテキスト情報が提供されていません"}

$(if [[ -n "$last_commit" ]]; then
    echo "最新のコミット:"
    echo "$last_commit"
fi)

セッション情報:
${session_info:-"セッション情報が提供されていません"}

---
🤖 Claude Code SubagentStop Hook
EOF
}

# サブエージェントセッション情報を収集
collect_subagent_session_info() {
    local session_info=""
    
    # Claude Codeのセッション情報を収集
    if [[ -n "$CLAUDE_SESSION_ID" ]]; then
        session_info="Session ID: $CLAUDE_SESSION_ID"
    fi
    
    # サブエージェント特有の情報
    if [[ -n "$CLAUDE_SUBAGENT_ID" ]]; then
        session_info="$session_info
Subagent ID: $CLAUDE_SUBAGENT_ID"
    fi
    
    # 作業ディレクトリ内の変更を確認
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        local changes=$(git status --porcelain 2>/dev/null | wc -l)
        local staged_changes=$(git diff --cached --name-only 2>/dev/null | wc -l)
        local unstaged_changes=$(git diff --name-only 2>/dev/null | wc -l)
        local untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
        
        session_info="$session_info
変更ファイル: $changes個
ステージング済み: $staged_changes個
未ステージング: $unstaged_changes個
未追跡ファイル: $untracked_files個"
    fi
    
    # サブエージェント実行時間を計算
    if [[ -n "$CLAUDE_SUBAGENT_START_TIME" ]]; then
        local subagent_duration=$(calculate_execution_time "$CLAUDE_SUBAGENT_START_TIME" "$(date +%s)")
        session_info="$session_info
サブエージェント実行時間: $subagent_duration"
    fi
    
    echo "$session_info"
}

# サブエージェント作業時間を推定
estimate_subagent_working_time() {
    local start_time="$1"
    local end_time="$2"
    
    # 環境変数またはファイルからサブエージェント開始時間を取得
    if [[ -n "$CLAUDE_SUBAGENT_START_TIME" ]]; then
        calculate_execution_time "$CLAUDE_SUBAGENT_START_TIME" "$end_time"
    elif [[ -n "$start_time" && -n "$end_time" ]]; then
        calculate_execution_time "$start_time" "$end_time"
    else
        echo "不明"
    fi
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
    if git rev-parse --is-inside-work-tree &> /dev/null; then
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

# サブエージェントコンテキスト情報を収集
collect_subagent_context() {
    local context=""
    
    # Task tool関連の情報
    if [[ -n "$CLAUDE_TASK_DESCRIPTION" ]]; then
        context="タスク説明: $CLAUDE_TASK_DESCRIPTION"
    fi
    
    if [[ -n "$CLAUDE_PARENT_SESSION_ID" ]]; then
        context="$context
親セッションID: $CLAUDE_PARENT_SESSION_ID"
    fi
    
    # サブエージェントのツール使用履歴
    if [[ -n "$CLAUDE_TOOLS_USED" ]]; then
        context="$context
使用されたツール: $CLAUDE_TOOLS_USED"
    fi
    
    echo "$context"
}

# JSON入力から停止制御情報を処理
process_stop_control() {
    local json_input="$1"
    
    # JSON入力が提供されている場合、stop_hook_activeを確認
    if [[ -n "$json_input" ]]; then
        local stop_hook_active=$(echo "$json_input" | jq -r '.stop_hook_active // false' 2>/dev/null)
        
        # 無限ループを防ぐため、stop_hook_activeがtrueの場合は早期終了
        if [[ "$stop_hook_active" == "true" ]]; then
            log_warning "stop_hook_activeがtrueです。無限ループを防ぐため、処理を終了します"
            return 1
        fi
    fi
    
    return 0
}

# メイン処理
main() {
    local task_description="$1"
    local custom_result_summary="$2"
    local session_start_time="$3"
    local json_input="$4"
    
    log_info "SubagentStopフックが開始されました"
    
    # 停止制御情報を処理
    if ! process_stop_control "$json_input"; then
        return 0
    fi
    
    # サブエージェントセッション情報を収集
    local session_info=$(collect_subagent_session_info)
    
    # サブエージェント作業時間を推定
    local end_time=$(date +%s)
    local working_time=$(estimate_subagent_working_time "$session_start_time" "$end_time")
    
    # サブエージェント作業結果の要約を生成
    local result_summary
    if [[ -n "$custom_result_summary" ]]; then
        result_summary="$custom_result_summary"
    else
        result_summary=$(generate_subagent_result_summary)
    fi
    
    # サブエージェントコンテキスト情報を収集
    local subagent_context=$(collect_subagent_context)
    
    # サブエージェント作業完了メッセージを作成
    local message=$(create_subagent_completion_message "$session_info" "$working_time" "$task_description" "$result_summary" "$subagent_context")
    
    # Slack通知を送信
    send_notifications "subagent_stop" "$message"
    
    # 実行時間を計算
    local hook_execution_time=$(calculate_execution_time "$START_TIME" "$end_time")
    
    log_info "SubagentStopフックが完了しました (実行時間: $hook_execution_time)"
}

# 引数の処理
task_description="${1:-}"
custom_result_summary="${2:-}"
session_start_time="${3:-$CLAUDE_SUBAGENT_START_TIME}"

# 標準入力からJSON入力を読み取り（Claude Code Hooksの標準的な入力方式）
json_input=""
if [[ ! -t 0 ]]; then
    json_input=$(cat)
fi

# 環境変数から情報を取得
if [[ -z "$task_description" && -n "$CLAUDE_TASK_DESCRIPTION" ]]; then
    task_description="$CLAUDE_TASK_DESCRIPTION"
fi

# メイン処理を実行
main "$task_description" "$custom_result_summary" "$session_start_time" "$json_input"