#!/bin/bash

# デバッグ用スクリプト
echo "=== 設定ファイルパスのデバッグ ==="

# 環境変数の確認
echo "CLAUDE_HOOKS_CONFIG: '$CLAUDE_HOOKS_CONFIG'"

# スクリプト内での設定パス計算
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code-hooks-scripts"
CONFIG_FILE="${CLAUDE_HOOKS_CONFIG:-$CONFIG_DIR/config.json}"

echo "CONFIG_DIR: '$CONFIG_DIR'"
echo "CONFIG_FILE: '$CONFIG_FILE'"

# ファイルの存在確認
echo "設定ファイルの存在確認:"
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ 設定ファイルが存在します: $CONFIG_FILE"
    echo "ファイルサイズ: $(wc -c < "$CONFIG_FILE") bytes"
    echo "権限: $(ls -la "$CONFIG_FILE")"
else
    echo "❌ 設定ファイルが存在しません: $CONFIG_FILE"
fi

# jqでの読み込みテスト
echo
echo "=== jq読み込みテスト ==="
if [[ -f "$CONFIG_FILE" ]]; then
    echo "JSON構文チェック:"
    if jq '.' "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "✅ JSON構文は正しいです"
    else
        echo "❌ JSON構文エラー:"
        jq '.' "$CONFIG_FILE"
    fi
    
    echo
    echo "notification設定の取得:"
    jq -r ".hooks.notification.slack_notifications[]" "$CONFIG_FILE" 2>&1
fi