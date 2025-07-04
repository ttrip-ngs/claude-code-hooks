#!/bin/bash

# Claude Code Hooks セットアップスクリプト
# 設定ファイルを適切な場所にコピーして初期設定を行う

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code-hooks-scripts"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo "=== Claude Code Hooks セットアップ ==="
echo

# 設定ディレクトリの作成
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "設定ディレクトリを作成します: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    echo "✅ 設定ディレクトリを作成しました"
else
    echo "✅ 設定ディレクトリが既に存在します: $CONFIG_DIR"
fi

# 設定ファイルの確認
if [[ -f "$CONFIG_FILE" ]]; then
    echo "⚠️  設定ファイルが既に存在します: $CONFIG_FILE"
    read -p "上書きしますか？ (y/N): " overwrite
    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
        echo "セットアップをキャンセルしました"
        exit 0
    fi
fi

# 設定例の選択
echo
echo "使用する設定例を選択してください:"
echo "1. minimal-config.json (最小構成)"
echo "2. claude-hooks-config.json (完全版)"
echo "3. multi-platform-config.json (複数プラットフォーム対応)"
echo

read -p "選択 (1-3): " choice

case $choice in
    1)
        source_file="$SCRIPT_DIR/examples/minimal-config.json"
        config_name="最小構成"
        ;;
    2)
        source_file="$SCRIPT_DIR/examples/claude-hooks-config.json"
        config_name="完全版"
        ;;
    3)
        source_file="$SCRIPT_DIR/examples/multi-platform-config.json"
        config_name="複数プラットフォーム対応"
        ;;
    *)
        echo "❌ 無効な選択です"
        exit 1
        ;;
esac

# 設定ファイルをコピー
if [[ -f "$source_file" ]]; then
    cp "$source_file" "$CONFIG_FILE"
    echo "✅ 設定ファイルをコピーしました ($config_name)"
    echo "   コピー先: $CONFIG_FILE"
else
    echo "❌ 設定例が見つかりません: $source_file"
    exit 1
fi

# 権限設定
chmod 600 "$CONFIG_FILE"
echo "✅ 設定ファイルの権限を設定しました (600)"

echo
echo "=== 次のステップ ==="
echo "1. 設定ファイルを編集してWebhook URLを設定:"
echo "   nano $CONFIG_FILE"
echo
echo "2. テストスクリプトで動作確認:"
echo "   cd /path/to/claude-code-hooks-scripts"
echo "   export CLAUDE_HOOKS_CONFIG=\"$CONFIG_FILE\""
echo "   ./test_notifications.sh"
echo
echo "3. Claude Codeの設定でhooksを有効化"
echo
echo "✅ セットアップが完了しました！"