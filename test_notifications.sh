#!/bin/bash

# Claude Code Hooks テストスクリプト
# hooksに登録する前に通知機能をテストするためのスクリプト

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 設定ファイルのパスを指定（テスト用は同一ディレクトリ、本番は$HOME/.config/claude-code/hooks.json）
export CLAUDE_HOOKS_CONFIG="$SCRIPT_DIR/test-config.json"

echo "=== Claude Code Hooks テスト ==="
echo "設定ファイル: $CLAUDE_HOOKS_CONFIG"
echo

# 設定ファイルの存在確認
if [[ ! -f "$CLAUDE_HOOKS_CONFIG" ]]; then
    echo "❌ 設定ファイルが見つかりません: $CLAUDE_HOOKS_CONFIG"
    echo "test-config.json を編集して、Webhook URLを設定してください"
    exit 1
fi

# jqの存在確認
if ! command -v jq &> /dev/null; then
    echo "❌ jqコマンドが見つかりません"
    echo "インストールしてください: sudo apt-get install jq"
    exit 1
fi

# Webhook URLの設定確認
webhook_url=$(jq -r '.hooks.notification.slack_notifications[0].webhook_url' "$CLAUDE_HOOKS_CONFIG")
if [[ "$webhook_url" == "YOUR_WEBHOOK_URL_HERE" ]]; then
    echo "❌ Webhook URLが設定されていません"
    echo "test-config.json を編集して、実際のWebhook URLを設定してください"
    exit 1
fi

echo "✅ 設定ファイルの検証が完了しました"
echo

# テストメニュー
while true; do
    echo "=== テストメニュー ==="
    echo "1. Notification Hook のテスト"
    echo "2. Stop Hook のテスト"
    echo "3. 設定ファイルの確認"
    echo "4. 終了"
    echo
    read -p "選択してください (1-4): " choice
    
    case $choice in
        1)
            echo
            echo "=== Notification Hook テスト ==="
            echo "通知種別を選択してください:"
            echo "1. info"
            echo "2. warning"
            echo "3. error"
            echo "4. success"
            echo "5. confirmation"
            read -p "選択 (1-5): " type_choice
            
            case $type_choice in
                1) type="info" ;;
                2) type="warning" ;;
                3) type="error" ;;
                4) type="success" ;;
                5) type="confirmation" ;;
                *) type="info" ;;
            esac
            
            message="これはテスト通知です (種別: $type)"
            context="テスト実行時刻: $(date '+%Y-%m-%d %H:%M:%S')"
            
            echo "通知を送信中..."
            "$SCRIPT_DIR/hooks/notification/slack_notify.sh" "$type" "$message" "$context"
            echo "✅ 通知テストが完了しました"
            ;;
        2)
            echo
            echo "=== Stop Hook テスト ==="
            instructions="テスト実行: Claude Code Hooksの動作確認"
            result_summary="- 設定ファイルの検証
- 通知機能のテスト
- スクリプトの動作確認"
            
            echo "作業完了通知を送信中..."
            "$SCRIPT_DIR/hooks/stop/slack_notify.sh" "$instructions" "$result_summary"
            echo "✅ 作業完了通知テストが完了しました"
            ;;
        3)
            echo
            echo "=== 設定ファイル確認 ==="
            echo "ファイルパス: $CLAUDE_HOOKS_CONFIG"
            echo "内容:"
            cat "$CLAUDE_HOOKS_CONFIG" | jq '.'
            ;;
        4)
            echo "テストを終了します"
            exit 0
            ;;
        *)
            echo "❌ 無効な選択です"
            ;;
    esac
    echo
done