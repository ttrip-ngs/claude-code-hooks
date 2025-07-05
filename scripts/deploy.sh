#!/bin/bash

# Claude Code Hooks Scripts デプロイメントスクリプト
# 本番環境への安全なデプロイメントを支援

set -e  # エラー時に終了

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ログ出力関数
log_info() {
    echo "[DEPLOY] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo "[DEPLOY ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

# 使用方法を表示
show_usage() {
    cat << EOF
Claude Code Hooks Scripts デプロイメントスクリプト

使用方法:
  $0 [環境] [デプロイ先ディレクトリ]

引数:
  環境                  production, staging, development のいずれか
  デプロイ先ディレクトリ  デプロイ先の絶対パス

例:
  $0 production ~/prod/claude-code-hooks-scripts
  $0 staging ~/staging/claude-code-hooks-scripts

オプション:
  -h, --help           この使用方法を表示
  --dry-run           実際のデプロイを行わずに確認のみ
  --force             既存ディレクトリがある場合も強制実行

環境変数:
  DEPLOY_DRY_RUN=1     ドライラン実行
  DEPLOY_FORCE=1       強制実行
EOF
}

# 引数解析
parse_arguments() {
    DRY_RUN="${DEPLOY_DRY_RUN:-0}"
    FORCE="${DEPLOY_FORCE:-0}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            *)
                if [[ -z "$ENVIRONMENT" ]]; then
                    ENVIRONMENT="$1"
                elif [[ -z "$DEPLOY_DIR" ]]; then
                    DEPLOY_DIR="$1"
                else
                    log_error "不明な引数: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# 引数検証
validate_arguments() {
    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "環境が指定されていません"
        show_usage
        exit 1
    fi
    
    if [[ "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "development" ]]; then
        log_error "無効な環境: $ENVIRONMENT"
        log_error "有効な環境: production, staging, development"
        exit 1
    fi
    
    if [[ -z "$DEPLOY_DIR" ]]; then
        log_error "デプロイ先ディレクトリが指定されていません"
        show_usage
        exit 1
    fi
    
    # 絶対パスに変換
    DEPLOY_DIR="$(cd "$(dirname "$DEPLOY_DIR")" 2>/dev/null && pwd)/$(basename "$DEPLOY_DIR")" || {
        log_error "無効なデプロイ先ディレクトリ: $DEPLOY_DIR"
        exit 1
    }
}

# 前提条件チェック
check_prerequisites() {
    log_info "前提条件をチェックしています..."
    
    # 必要コマンドの確認
    local missing_commands=()
    
    for cmd in git rsync jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "必要なコマンドが見つかりません: ${missing_commands[*]}"
        exit 1
    fi
    
    # Gitリポジトリの状態確認
    if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        log_error "Gitリポジトリではありません: $PROJECT_ROOT"
        exit 1
    fi
    
    # 未コミットの変更確認
    if [[ -n "$(git -C "$PROJECT_ROOT" status --porcelain)" ]]; then
        log_error "未コミットの変更があります。コミットしてからデプロイしてください"
        git -C "$PROJECT_ROOT" status --short
        exit 1
    fi
    
    log_info "前提条件チェック完了"
}

# デプロイ先ディレクトリの準備
prepare_deploy_directory() {
    log_info "デプロイ先ディレクトリを準備しています: $DEPLOY_DIR"
    
    if [[ -d "$DEPLOY_DIR" ]]; then
        if [[ "$FORCE" == "1" ]]; then
            log_info "既存ディレクトリを削除します"
            if [[ "$DRY_RUN" == "0" ]]; then
                rm -rf "$DEPLOY_DIR"
            fi
        else
            log_error "デプロイ先ディレクトリが既に存在します: $DEPLOY_DIR"
            log_error "--force オプションを使用するか、別のディレクトリを指定してください"
            exit 1
        fi
    fi
    
    # 親ディレクトリの作成
    local parent_dir="$(dirname "$DEPLOY_DIR")"
    if [[ ! -d "$parent_dir" ]]; then
        log_info "親ディレクトリを作成します: $parent_dir"
        if [[ "$DRY_RUN" == "0" ]]; then
            mkdir -p "$parent_dir"
        fi
    fi
}

# ファイルのデプロイ
deploy_files() {
    log_info "ファイルをデプロイしています..."
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_info "[DRY RUN] git clone $PROJECT_ROOT $DEPLOY_DIR"
        return 0
    fi
    
    # Gitリポジトリをクローン
    git clone "$PROJECT_ROOT" "$DEPLOY_DIR"
    
    # .gitディレクトリを削除（本番環境では不要）
    if [[ "$ENVIRONMENT" == "production" ]]; then
        rm -rf "$DEPLOY_DIR/.git"
    fi
    
    log_info "ファイルデプロイ完了"
}

# 環境設定ファイルの作成
setup_environment_config() {
    log_info "環境設定ファイルを作成しています..."
    
    local config_template="$DEPLOY_DIR/config/$ENVIRONMENT.env.template"
    local config_file="$DEPLOY_DIR/.env"
    
    if [[ ! -f "$config_template" ]]; then
        log_error "設定テンプレートが見つかりません: $config_template"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_info "[DRY RUN] cp $config_template $config_file"
        log_info "[DRY RUN] chmod 600 $config_file"
        return 0
    fi
    
    # テンプレートから設定ファイルを作成
    cp "$config_template" "$config_file"
    chmod 600 "$config_file"
    
    log_info "設定ファイルを作成しました: $config_file"
    log_info "実際の値を設定してください:"
    echo "  nano $config_file"
}

# Claude Code設定例の表示
show_claude_config() {
    log_info "Claude Code設定例:"
    cat << EOF

~/.claude/settings.toml に以下を追加してください:

# Claude Code Hooks ($ENVIRONMENT 環境)
[[hooks]]
event = "Stop"
command = "$DEPLOY_DIR/hooks/stop/slack.sh"

[[hooks]]
event = "Notification"
command = "$DEPLOY_DIR/hooks/notification/slack.sh"

[[hooks]]
event = "SubagentStop"
command = "$DEPLOY_DIR/hooks/subagent-stop/slack.sh"

EOF
}

# デプロイ後の検証
verify_deployment() {
    log_info "デプロイメントを検証しています..."
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_info "[DRY RUN] デプロイメント検証をスキップ"
        return 0
    fi
    
    # 必要なファイルの存在確認
    local required_files=(
        "$DEPLOY_DIR/hooks/stop/slack.sh"
        "$DEPLOY_DIR/hooks/notification/slack.sh"
        "$DEPLOY_DIR/hooks/subagent-stop/slack.sh"
        "$DEPLOY_DIR/lib/slack_messenger.sh"
        "$DEPLOY_DIR/lib/config_loader.sh"
        "$DEPLOY_DIR/.env"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "必要なファイルが見つかりません: $file"
            exit 1
        fi
    done
    
    # 実行権限の確認
    for script in "$DEPLOY_DIR/hooks"/*/*.sh; do
        if [[ ! -x "$script" ]]; then
            log_error "実行権限がありません: $script"
            exit 1
        fi
    done
    
    log_info "デプロイメント検証完了"
}

# メイン処理
main() {
    log_info "Claude Code Hooks Scripts デプロイメントを開始します"
    
    parse_arguments "$@"
    validate_arguments
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_info "ドライラン実行モード"
    fi
    
    log_info "デプロイ設定:"
    log_info "  環境: $ENVIRONMENT"
    log_info "  デプロイ先: $DEPLOY_DIR"
    log_info "  ドライラン: $([[ $DRY_RUN == 1 ]] && echo "Yes" || echo "No")"
    log_info "  強制実行: $([[ $FORCE == 1 ]] && echo "Yes" || echo "No")"
    
    check_prerequisites
    prepare_deploy_directory
    deploy_files
    setup_environment_config
    verify_deployment
    
    log_info "デプロイメントが完了しました！"
    echo ""
    log_info "次のステップ:"
    echo "1. 設定ファイルの編集: nano $DEPLOY_DIR/.env"
    echo "2. 実際の Slack Webhook URL を設定"
    echo "3. Claude Code 設定の追加"
    echo ""
    show_claude_config
}

# スクリプト実行
main "$@"