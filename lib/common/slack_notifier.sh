#!/bin/bash

# Slack通知用の共通ライブラリ
# 複数の通知先に対応した柔軟な通知システム

# 設定ファイルのパスを取得（XDG Base Directory準拠）
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code-hooks-scripts"
CONFIG_FILE="${CLAUDE_HOOKS_CONFIG:-$CONFIG_DIR/config.json}"

# ログ出力用関数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

# 設定ファイルから通知先を読み込む
load_notification_config() {
    local hook_type="$1"
    
    # デバッグ出力
    log_info "設定ファイルパス: $CONFIG_FILE"
    log_info "フックタイプ: $hook_type"
    
    # 設定ディレクトリが存在しない場合は作成
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        log_info "設定ディレクトリを作成しました: $CONFIG_DIR"
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "設定ファイルが見つかりません: $CONFIG_FILE"
        log_info "設定ファイル例を参照して作成してください"
        return 1
    fi
    
    # jqコマンドの存在チェック
    if ! command -v jq &> /dev/null; then
        log_error "jqコマンドが見つかりません。インストールしてください。"
        return 1
    fi
    
    # 設定を読み込み - コンパクトJSONフォーマットで各オブジェクトを1行に
    jq -c ".hooks.$hook_type.slack_notifications[]" "$CONFIG_FILE" 2>/dev/null
}

# Slack通知を送信する
send_slack_notification() {
    local channel="$1"
    local message="$2"
    local webhook_url="$3"
    local thread_ts="$4"
    
    # メッセージペイロードを作成
    local payload=$(jq -n \
        --arg channel "$channel" \
        --arg text "$message" \
        --arg thread_ts "$thread_ts" \
        '{
            channel: $channel,
            text: $text,
            username: "Claude Code",
            icon_emoji: ":robot_face:"
        } + (if $thread_ts != "" then {thread_ts: $thread_ts} else {} end)')
    
    # Webhook URL経由で送信
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$webhook_url")
    
    if [[ $? -eq 0 ]]; then
        log_info "Slack通知を送信しました: $channel"
        return 0
    else
        log_error "Slack通知の送信に失敗しました: $channel"
        return 1
    fi
}

# 複数の通知先に一括送信
send_notifications() {
    local hook_type="$1"
    local message="$2"
    local thread_ts="$3"
    
    log_info "通知を送信中: $hook_type"
    
    # 設定ファイルから通知先を読み込み
    local notification_configs
    notification_configs=$(load_notification_config "$hook_type")
    
    if [[ -z "$notification_configs" ]]; then
        log_info "通知設定が見つかりません: $hook_type"
        return 0
    fi
    
    # 各通知先に送信
    echo "$notification_configs" | while IFS= read -r config; do
        if [[ -n "$config" && "$config" != "null" ]]; then
            local channel=$(echo "$config" | jq -r '.channel')
            local webhook_url=$(echo "$config" | jq -r '.webhook_url')
            local enabled=$(echo "$config" | jq -r '.enabled // true')
            
            if [[ "$enabled" == "true" ]]; then
                send_slack_notification "$channel" "$message" "$webhook_url" "$thread_ts"
            else
                log_info "通知が無効化されています: $channel"
            fi
        fi
    done
}

# 環境情報を取得
get_environment_info() {
    local repo_name=""
    local branch_name=""
    local working_dir="$PWD"
    
    # Gitリポジトリ情報を取得
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        repo_name=$(basename "$(git rev-parse --show-toplevel)")
        branch_name=$(git rev-parse --abbrev-ref HEAD)
    fi
    
    echo "Repository: ${repo_name:-N/A}"
    echo "Branch: ${branch_name:-N/A}"
    echo "Working Directory: $working_dir"
}

# 実行時間を計算
calculate_execution_time() {
    local start_time="$1"
    local end_time="$2"
    
    if [[ -n "$start_time" && -n "$end_time" ]]; then
        local duration=$((end_time - start_time))
        echo "${duration}秒"
    else
        echo "N/A"
    fi
}

# エラーハンドリング
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "エラーが発生しました (行: $line_number, 終了コード: $exit_code)"
    fi
}

# エラートラップを設定
trap 'handle_error $LINENO' ERR