#!/bin/bash

# Claude Code Hooks Scripts - 機密情報検出スクリプト
#
# 使用方法:
#   ./scripts/security_scan.sh           # 全ファイルスキャン
#   ./scripts/security_scan.sh --git     # Git追跡ファイルのみ
#   ./scripts/security_scan.sh --strict  # 厳格モード

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# デフォルト設定
SCAN_GIT_ONLY=false
STRICT_MODE=false
VERBOSE=false
EXIT_ON_FOUND=true

# ログ出力関数
log_info() {
    echo "[INFO] $(date '+%H:%M:%S') $1"
}

log_warn() {
    echo "[WARN] $(date '+%H:%M:%S') $1" >&2
}

log_error() {
    echo "[ERROR] $(date '+%H:%M:%S') $1" >&2
}

log_found() {
    echo "[FOUND] $1" >&2
}

# 使用方法を表示
show_usage() {
    cat << EOF
機密情報検出スクリプト

使用方法:
  $0 [オプション]

オプション:
  --git          Git追跡ファイルのみスキャン
  --strict       厳格モード（偽陽性も含めて検出）
  --verbose      詳細出力
  --no-exit      機密情報が見つかってもスクリプトを終了しない
  -h, --help     この使用方法を表示

例:
  $0                    # 全ファイルスキャン
  $0 --git             # Git追跡ファイルのみ
  $0 --strict --verbose # 厳格モード・詳細出力
EOF
}

# 引数解析
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --git)
                SCAN_GIT_ONLY=true
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --no-exit)
                EXIT_ON_FOUND=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 機密情報パターン定義
define_patterns() {
    # 高リスクパターン（確実に機密情報）
    HIGH_RISK_PATTERNS=(
        # Slack Webhook URL (YOURというプレースホルダーを除外)
        "hooks\.slack\.com/services/(?!YOUR)[A-Z0-9]+/[A-Z0-9]+/[A-Za-z0-9_-]+"

        # JWT トークン
        "eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"

        # API キー（汎用）
        "['\"][a-zA-Z0-9_-]{32,}['\"]"

        # Stripe API キー
        "sk_live_[0-9a-zA-Z]{24}"
        "pk_live_[0-9a-zA-Z]{24}"

        # Google API キー
        "AIza[0-9A-Za-z\\-_]{35}"

        # AWS アクセスキー
        "AKIA[0-9A-Z]{16}"

        # GitHub トークン
        "ghp_[A-Za-z0-9]{36}"
        "gho_[A-Za-z0-9]{36}"
        "ghu_[A-Za-z0-9]{36}"
        "ghs_[A-Za-z0-9]{36}"
        "ghr_[A-Za-z0-9]{36}"
    )

    # 中リスクパターン（文脈により機密情報の可能性）
    MEDIUM_RISK_PATTERNS=(
        # 長い英数字文字列（32文字以上）
        "[a-zA-Z0-9]{32,}"

        # BASE64エンコード（長いもの）
        "[A-Za-z0-9+/]{40,}={0,2}"

        # 16進数文字列（長いもの）
        "[a-fA-F0-9]{32,}"

        # パスワード的な文字列
        "(password|passwd|pwd|secret|key|token)['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    )

    # 厳格モードでのみチェックするパターン
    STRICT_PATTERNS=(
        # Slack ID パターン
        "[DUBCTW][A-Z0-9]{8,}"

        # UUID
        "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"

        # IP アドレス（プライベート範囲）
        "192\.168\.[0-9]{1,3}\.[0-9]{1,3}"
        "10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
        "172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}"
    )
}

# ファイルリストを取得
get_file_list() {
    if [[ "$SCAN_GIT_ONLY" == true ]]; then
        log_info "Git追跡ファイルのみをスキャンします"
        cd "$PROJECT_ROOT"
        git ls-files
    else
        log_info "全ファイルをスキャンします"
        find "$PROJECT_ROOT" -type f \
            ! -path "*/\.*" \
            ! -path "*/node_modules/*" \
            ! -path "*/\.git/*" \
            ! -name "*.log" \
            ! -name "*.tmp" \
            ! -name "*.cache"
    fi
}

# パターンマッチング
scan_file_for_patterns() {
    local file="$1"
    local patterns=("${@:2}")
    local found_count=0

    # ファイルが読み取り可能かチェック
    if [[ ! -r "$file" ]]; then
        [[ "$VERBOSE" == true ]] && log_warn "読み取り不可: $file"
        return 0
    fi

    # バイナリファイルをスキップ
    if file "$file" | grep -q "binary"; then
        [[ "$VERBOSE" == true ]] && log_info "バイナリファイルをスキップ: $file"
        return 0
    fi

    # 各パターンでチェック
    for pattern in "${patterns[@]}"; do
        if [[ "$VERBOSE" == true ]]; then
            log_info "パターンチェック: $pattern in $file"
        fi

        local matches
        matches=$(rg -n "$pattern" "$file" 2>/dev/null || true)

        if [[ -n "$matches" ]]; then
            log_found "機密情報の可能性 in $file:"
            echo "$matches" | while IFS= read -r line; do
                log_found "  $line"
            done
            echo ""
            ((found_count++)) || true
        fi
    done

    return $found_count
}

# メインスキャン処理
main_scan() {
    log_info "🔍 機密情報スキャンを開始します"
    log_info "プロジェクトルート: $PROJECT_ROOT"

    if [[ "$STRICT_MODE" == true ]]; then
        log_info "厳格モードが有効です"
    fi

    define_patterns

    local total_files=0
    local total_issues=0
    local high_risk_issues=0
    local medium_risk_issues=0
    local strict_issues=0

    # ファイル一覧を取得
    local file_list
    file_list=$(get_file_list)

    if [[ -z "$file_list" ]]; then
        log_warn "スキャン対象ファイルが見つかりませんでした"
        return 0
    fi

    # 高リスクパターンのスキャン
    log_info "🚨 高リスクパターンをスキャン中..."
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        ((total_files++)) || true

        local result
        scan_file_for_patterns "$file" "${HIGH_RISK_PATTERNS[@]}"
        result=$?
        ((high_risk_issues += result)) || true
    done <<< "$file_list"

    # 中リスクパターンのスキャン
    log_info "⚠️  中リスクパターンをスキャン中..."
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local result
        scan_file_for_patterns "$file" "${MEDIUM_RISK_PATTERNS[@]}"
        result=$?
        ((medium_risk_issues += result)) || true
    done <<< "$file_list"

    # 厳格モードでの追加スキャン
    if [[ "$STRICT_MODE" == true ]]; then
        log_info "🔍 厳格モードパターンをスキャン中..."
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue

            local result
            scan_file_for_patterns "$file" "${STRICT_PATTERNS[@]}"
            result=$?
            ((strict_issues += result)) || true
        done <<< "$file_list"
    fi

    # 結果サマリー
    total_issues=$((high_risk_issues + medium_risk_issues + strict_issues))

    echo ""
    echo "========================================"
    echo "スキャン結果サマリー"
    echo "========================================"
    echo "スキャンファイル数: $total_files"
    echo "高リスク項目: $high_risk_issues"
    echo "中リスク項目: $medium_risk_issues"
    if [[ "$STRICT_MODE" == true ]]; then
        echo "厳格モード項目: $strict_issues"
    fi
    echo "合計検出項目: $total_issues"
    echo "========================================"

    # 終了判定
    if [[ $total_issues -gt 0 ]]; then
        if [[ $high_risk_issues -gt 0 ]]; then
            log_error "🚨 高リスクの機密情報が検出されました！"
            log_error "即座に対応が必要です。"
        fi

        if [[ $medium_risk_issues -gt 0 ]]; then
            log_warn "⚠️  中リスクの機密情報が検出されました。"
            log_warn "確認と対応を検討してください。"
        fi

        if [[ "$EXIT_ON_FOUND" == true ]]; then
            exit 1
        fi
    else
        log_info "✅ 機密情報は検出されませんでした。"
    fi
}

# 必要ツールのチェック
check_dependencies() {
    local missing_tools=()

    for tool in rg file; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "必要なツールが見つかりません: ${missing_tools[*]}"
        log_error "以下でインストールしてください:"
        log_error "  Ubuntu/Debian: sudo apt-get install ripgrep file"
        log_error "  macOS: brew install ripgrep file"
        exit 1
    fi
}

# メイン処理
main() {
    parse_arguments "$@"
    check_dependencies

    cd "$PROJECT_ROOT"
    main_scan
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
