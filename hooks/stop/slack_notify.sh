#!/bin/bash

# Claude Code Stop Hook - Slack通知
# Claude Code応答終了時にSlackに作業完了通知を送信

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../../lib/common" && pwd)"

# 共通ライブラリを読み込み
source "$LIB_DIR/slack_notifier.sh"

# 実行開始時間を記録
START_TIME=$(date +%s)

# 作業完了メッセージを作成
create_completion_message() {
    local session_info="$1"
    local working_time="$2"
    local instructions="$3"
    local result_summary="$4"
    
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
✅ **作業完了通知**

完了時刻: $current_time

$env_info

作業時間: ${working_time:-"N/A"}

指示:
${instructions:-"指示情報が提供されていません"}

作業内容:
${result_summary:-"作業結果の詳細は記録されていません"}

$(if [[ -n "$last_commit" ]]; then
    echo "最新のコミット:"
    echo "$last_commit"
fi)

セッション情報:
${session_info:-"セッション情報が提供されていません"}

---
🤖 Claude Code Stop Hook
EOF
}

# セッション情報を収集
collect_session_info() {
    local session_info=""
    
    # Claude Codeのセッション情報を収集
    if [[ -n "$CLAUDE_SESSION_ID" ]]; then
        session_info="Session ID: $CLAUDE_SESSION_ID"
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
    
    # 実行時間を計算
    if [[ -n "$CLAUDE_SESSION_START_TIME" ]]; then
        local session_duration=$(calculate_execution_time "$CLAUDE_SESSION_START_TIME" "$(date +%s)")
        session_info="$session_info
セッション実行時間: $session_duration"
    fi
    
    echo "$session_info"
}

# 作業時間を推定
estimate_working_time() {
    local start_time="$1"
    local end_time="$2"
    
    # 環境変数またはファイルからセッション開始時間を取得
    if [[ -n "$CLAUDE_SESSION_START_TIME" ]]; then
        calculate_execution_time "$CLAUDE_SESSION_START_TIME" "$end_time"
    elif [[ -n "$start_time" && -n "$end_time" ]]; then
        calculate_execution_time "$start_time" "$end_time"
    else
        echo "不明"
    fi
}

# 作業結果の要約を生成
generate_result_summary() {
    local summary=""
    
    # Gitコミットから作業内容を推定
    if git rev-parse --is-inside-work-tree &> /dev/null; then
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

# メイン処理
main() {
    local instructions="$1"
    local custom_result_summary="$2"
    local session_start_time="$3"
    
    log_info "Stopフックが開始されました"
    
    # セッション情報を収集
    local session_info=$(collect_session_info)
    
    # 作業時間を推定
    local end_time=$(date +%s)
    local working_time=$(estimate_working_time "$session_start_time" "$end_time")
    
    # 作業結果の要約を生成
    local result_summary
    if [[ -n "$custom_result_summary" ]]; then
        result_summary="$custom_result_summary"
    else
        result_summary=$(generate_result_summary)
    fi
    
    # 作業完了メッセージを作成
    local message=$(create_completion_message "$session_info" "$working_time" "$instructions" "$result_summary")
    
    # Slack通知を送信
    send_notifications "stop" "$message"
    
    # 実行時間を計算
    local hook_execution_time=$(calculate_execution_time "$START_TIME" "$end_time")
    
    log_info "Stopフックが完了しました (実行時間: $hook_execution_time)"
}

# 引数の処理
instructions="${1:-}"
custom_result_summary="${2:-}"
session_start_time="${3:-$CLAUDE_SESSION_START_TIME}"

# 環境変数から情報を取得
if [[ -z "$instructions" && -n "$CLAUDE_USER_INSTRUCTIONS" ]]; then
    instructions="$CLAUDE_USER_INSTRUCTIONS"
fi

# メイン処理を実行
main "$instructions" "$custom_result_summary" "$session_start_time"