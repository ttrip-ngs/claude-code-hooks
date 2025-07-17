#!/bin/bash

# 設定ファイル読み込みライブラリ
# 開発・本番環境の分離と柔軟な設定管理

# ログ出力関数
config_log_info() {
    echo "[CONFIG] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

config_log_error() {
    echo "[CONFIG ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

# 設定ファイルを読み込む
load_config() {
    # スクリプトのディレクトリを特定（呼び出し元スクリプト基準）
    local caller_script="${BASH_SOURCE[1]}"
    local script_dir="$(cd "$(dirname "$caller_script")" && pwd)"
    local project_root="$(cd "$script_dir/.." && pwd)"

    # 環境の決定
    local environment="${CLAUDE_HOOKS_ENV:-}"

    # 環境が指定されていない場合、ディレクトリパスから推定
    if [[ -z "$environment" ]]; then
        if echo "$project_root" | grep -q "/dev/\|/development/\|/staging/"; then
            environment="development"
        elif echo "$project_root" | grep -q "/prod/\|/production/"; then
            environment="production"
        else
            environment="development"  # デフォルト
        fi
    fi

    config_log_info "環境: $environment"
    config_log_info "プロジェクトルート: $project_root"

    # 設定ファイルの優先順位（上から順に評価）
    local config_files=(
        "$CLAUDE_HOOKS_CONFIG"                    # 1. 明示的指定
        "$project_root/.env"                      # 2. プロジェクトルート
        "$project_root/config/$environment.env"   # 3. 環境別設定
        "$project_root/config/default.env"        # 4. デフォルト設定
    )

    local config_loaded=false

    # 設定ファイルを順番に試行
    for config_file in "${config_files[@]}"; do
        if [[ -n "$config_file" && -f "$config_file" ]]; then
            # ファイルの権限チェック
            if [[ ! -r "$config_file" ]]; then
                config_log_error "設定ファイルが読み取れません: $config_file"
                continue
            fi

            # 設定ファイルを読み込み
            set -a  # 以降の変数を自動的にexport
            source "$config_file"
            set +a  # exportの自動化を停止

            config_log_info "設定ファイルを読み込みました: $config_file"
            config_loaded=true
            break
        fi
    done

    # 設定ファイルが見つからない場合の警告
    if [[ "$config_loaded" == false ]]; then
        config_log_info "設定ファイルが見つかりません。環境変数またはデフォルト値を使用します"
    fi

    # 環境変数の設定（設定ファイルで上書きされていない場合のデフォルト値）
    export ENVIRONMENT="${ENVIRONMENT:-$environment}"
    export SLACK_ICON="${SLACK_ICON:-:robot_face:}"
    export SLACK_USERNAME="${SLACK_USERNAME:-Claude Code}"
    export LOG_LEVEL="${LOG_LEVEL:-info}"

    # 環境に応じたデフォルト値の調整
    if [[ "$ENVIRONMENT" == "development" ]]; then
        export SLACK_USERNAME="${SLACK_USERNAME} [DEV]"
        export LOG_LEVEL="${LOG_LEVEL:-debug}"
    elif [[ "$ENVIRONMENT" == "staging" ]]; then
        export SLACK_USERNAME="${SLACK_USERNAME} [STAGING]"
    fi

    # 必須設定の検証
    validate_required_config
}

# 必須設定の検証
validate_required_config() {
    local missing_config=()

    # 必須の環境変数をチェック
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        missing_config+=("SLACK_WEBHOOK_URL")
    fi

    if [[ -z "$SLACK_CHANNEL" ]]; then
        missing_config+=("SLACK_CHANNEL")
    fi

    # 必須設定が不足している場合はエラー
    if [[ ${#missing_config[@]} -gt 0 ]]; then
        config_log_error "必須の設定が不足しています: ${missing_config[*]}"
        config_log_error "設定ファイルまたは環境変数で設定してください"
        return 1
    fi

    config_log_info "設定検証が完了しました"
    return 0
}

# 設定情報の表示
show_config() {
    echo "========================================="
    echo "Claude Code Hooks 設定情報"
    echo "========================================="
    echo "環境: ${ENVIRONMENT:-N/A}"
    echo "Slack Webhook: ${SLACK_WEBHOOK_URL:0:50}..." # URLの最初の50文字のみ表示
    echo "Slack チャンネル: ${SLACK_CHANNEL:-N/A}"
    echo "Slack ユーザー名: ${SLACK_USERNAME:-N/A}"
    echo "Slack アイコン: ${SLACK_ICON:-N/A}"
    echo "ログレベル: ${LOG_LEVEL:-N/A}"
    echo "========================================="
}

# 設定ファイルテンプレートを生成
generate_config_template() {
    local template_type="${1:-development}"
    local output_file="$2"

    case "$template_type" in
        "development")
            cat > "$output_file" << 'EOF'
# 開発環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/DEV/WEBHOOK"
SLACK_CHANNEL="#development-alerts"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":construction:"
ENVIRONMENT="development"
LOG_LEVEL="debug"
EOF
            ;;
        "production")
            cat > "$output_file" << 'EOF'
# 本番環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/PROD/WEBHOOK"
SLACK_CHANNEL="UJM1V2AAH"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":robot_face:"
ENVIRONMENT="production"
LOG_LEVEL="info"
EOF
            ;;
        "staging")
            cat > "$output_file" << 'EOF'
# ステージング環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/STAGING/WEBHOOK"
SLACK_CHANNEL="#staging-alerts"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":warning:"
ENVIRONMENT="staging"
LOG_LEVEL="info"
EOF
            ;;
        *)
            config_log_error "不明なテンプレートタイプ: $template_type"
            return 1
            ;;
    esac

    chmod 600 "$output_file"  # 適切な権限を設定
    config_log_info "$template_type 環境の設定テンプレートを作成しました: $output_file"
}

# 設定ファイルの初期化
init_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/.." && pwd)"
    local config_dir="$project_root/config"

    # configディレクトリの作成
    mkdir -p "$config_dir"

    # 各環境のテンプレートを生成
    generate_config_template "development" "$config_dir/development.env.template"
    generate_config_template "production" "$config_dir/production.env.template"
    generate_config_template "staging" "$config_dir/staging.env.template"

    # .gitignoreの更新
    local gitignore="$project_root/.gitignore"
    if [[ -f "$gitignore" ]]; then
        if ! grep -q "^\.env$" "$gitignore"; then
            echo ".env" >> "$gitignore"
        fi
        if ! grep -q "^config/local\.env$" "$gitignore"; then
            echo "config/local.env" >> "$gitignore"
        fi
    fi

    config_log_info "設定ファイルテンプレートの初期化が完了しました"
    echo "次のステップ:"
    echo "1. $config_dir/development.env.template をコピーして .env を作成"
    echo "2. .env ファイルで実際の値を設定"
    echo "3. chmod 600 .env で権限を設定"
}
