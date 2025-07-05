#!/bin/bash

# Claude Code Hooks Scripts 環境設定スクリプト
# 
# 使用方法:
#   source examples/environment-setup.sh
#   または
#   . examples/environment-setup.sh

echo "Claude Code Hooks Scripts 環境設定を開始します..."

# ========================================
# 基本設定
# ========================================

# Slack Webhook URL (必須)
if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    echo "⚠️  SLACK_WEBHOOK_URL が設定されていません"
    echo "   以下のコマンドで設定してください:"
    echo "   export SLACK_WEBHOOK_URL=\"https://hooks.slack.com/services/YOUR/WEBHOOK/URL\""
    echo ""
fi

# Slack チャンネル (必須)
if [[ -z "$SLACK_CHANNEL" ]]; then
    echo "ℹ️  SLACK_CHANNEL が設定されていません。デフォルト設定を使用します"
    export SLACK_CHANNEL="UJM1V2AAH"
    echo "   設定値: $SLACK_CHANNEL"
    echo "   変更する場合: export SLACK_CHANNEL=\"your-channel-or-user-id\""
    echo ""
fi

# ========================================
# オプション設定
# ========================================

# Slack アイコン (オプション)
if [[ -z "$SLACK_ICON" ]]; then
    export SLACK_ICON=":robot_face:"
    echo "ℹ️  SLACK_ICON のデフォルト値を設定: $SLACK_ICON"
fi

# Slack ユーザー名 (オプション)
if [[ -z "$SLACK_USERNAME" ]]; then
    export SLACK_USERNAME="Claude Code"
    echo "ℹ️  SLACK_USERNAME のデフォルト値を設定: $SLACK_USERNAME"
fi

# ========================================
# スクリプトパス設定
# ========================================

# このスクリプトのディレクトリから相対パスを計算
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Claude Code Hooks Scripts のルートディレクトリ
export CLAUDE_HOOKS_ROOT="$PROJECT_ROOT"
echo "ℹ️  CLAUDE_HOOKS_ROOT を設定: $CLAUDE_HOOKS_ROOT"

# ========================================
# 依存関係チェック
# ========================================

echo ""
echo "依存関係をチェックしています..."

# jq コマンドチェック
if command -v jq &> /dev/null; then
    echo "✅ jq: $(jq --version)"
else
    echo "❌ jq: インストールされていません"
    echo "   インストール方法:"
    echo "   - Ubuntu/Debian: sudo apt-get install jq"
    echo "   - macOS: brew install jq"
    echo "   - CentOS/RHEL: sudo yum install jq"
fi

# curl コマンドチェック
if command -v curl &> /dev/null; then
    echo "✅ curl: $(curl --version | head -n1)"
else
    echo "❌ curl: インストールされていません"
    echo "   インストール方法:"
    echo "   - Ubuntu/Debian: sudo apt-get install curl"
    echo "   - macOS: brew install curl"
    echo "   - CentOS/RHEL: sudo yum install curl"
fi

# git コマンドチェック
if command -v git &> /dev/null; then
    echo "✅ git: $(git --version)"
else
    echo "⚠️  git: インストールされていません（環境情報取得でgit情報が利用できません）"
fi

# ========================================
# 設定確認
# ========================================

echo ""
echo "========================================="
echo "現在の設定:"
echo "========================================="
echo "SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL:-(未設定)}"
echo "SLACK_CHANNEL: ${SLACK_CHANNEL:-(未設定)}"
echo "SLACK_ICON: ${SLACK_ICON:-(未設定)}"
echo "SLACK_USERNAME: ${SLACK_USERNAME:-(未設定)}"
echo "CLAUDE_HOOKS_ROOT: ${CLAUDE_HOOKS_ROOT:-(未設定)}"
echo ""

# ========================================
# テスト実行案内
# ========================================

if [[ -n "$SLACK_WEBHOOK_URL" && -n "$SLACK_CHANNEL" ]]; then
    echo "✅ 基本設定が完了しました！"
    echo ""
    echo "テスト実行方法:"
    echo "  # Notification Hook テスト"
    echo "  $CLAUDE_HOOKS_ROOT/hooks/notification/slack.sh info \"テストメッセージ\""
    echo ""
    echo "  # Stop Hook テスト"
    echo "  $CLAUDE_HOOKS_ROOT/hooks/stop/slack.sh \"テスト作業\" \"テスト完了\" \"1分\""
    echo ""
    echo "  # SubagentStop Hook テスト"
    echo "  $CLAUDE_HOOKS_ROOT/hooks/subagent-stop/slack.sh \"テストタスク\" \"タスク完了\" \"30秒\""
else
    echo "⚠️  基本設定が不完全です。SLACK_WEBHOOK_URL を設定してください。"
fi

echo ""
echo "設定完了！Claude Code Hooks Scripts をお楽しみください 🚀"