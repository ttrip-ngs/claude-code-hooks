# 003_config_path_improvement.md

## 作業日時
2025-07-03

## タスク
設定ファイルパスを$HOME/.config/claude-code配下に改善

## 実施内容

### 1. 設定パスの変更理由
**問題点**: 
- `$HOME/.claude-hooks.json` では他の設定ファイルとの混在
- XDG Base Directory準拠でない

**改善点**:
- `$HOME/.config/claude-code/hooks.json` に変更
- XDG Base Directory仕様に準拠
- 設定ファイルの整理とセキュリティ向上

### 2. 実装した変更

#### 共通ライブラリの更新 (`lib/common/slack_notifier.sh`)
```bash
# 変更前
CONFIG_FILE="${CLAUDE_HOOKS_CONFIG:-$HOME/.claude-hooks.json}"

# 変更後  
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code"
CONFIG_FILE="${CLAUDE_HOOKS_CONFIG:-$CONFIG_DIR/hooks.json}"
```

**追加機能**:
- 設定ディレクトリの自動作成
- XDG_CONFIG_HOME環境変数の考慮
- より詳細なエラーメッセージ

#### セットアップスクリプトの作成 (`config/setup.sh`)
**機能**:
- 設定ディレクトリの自動作成
- 設定例の選択とコピー
- 適切な権限設定 (600)
- インタラクティブなセットアップ

**対応設定例**:
1. minimal-config.json (最小構成)
2. claude-hooks-config.json (完全版)
3. multi-platform-config.json (複数プラットフォーム対応)

### 3. ドキュメントの整備

#### セットアップガイド (`docs/setup.md`)
**内容**:
- 詳細なセットアップ手順
- 前提条件とパッケージインストール
- トラブルシューティング
- セキュリティ注意事項

**カバー範囲**:
- 自動/手動セットアップ
- 設定ファイル編集
- テスト実行
- Claude Code連携

### 4. 設定パスの柔軟性

#### 優先順位
1. `CLAUDE_HOOKS_CONFIG` 環境変数
2. `$XDG_CONFIG_HOME/claude-code/hooks.json`
3. `$HOME/.config/claude-code/hooks.json` (デフォルト)

#### 使用例
```bash
# カスタムパス
export CLAUDE_HOOKS_CONFIG="/custom/path/config.json"

# XDG準拠
export XDG_CONFIG_HOME="/custom/config"
# -> /custom/config/claude-code/hooks.json

# デフォルト
# -> $HOME/.config/claude-code/hooks.json
```

## 技術的な改善点

### 1. XDG Base Directory準拠
- Linux/Unixの標準的な設定ディレクトリ配置
- 他のアプリケーションとの統一性
- 設定ファイルの分離と整理

### 2. セキュリティ強化
- 設定ファイルの権限設定 (600)
- Webhook URLの保護
- ログ出力での機密情報の除外

### 3. ユーザビリティ向上
- 自動セットアップスクリプト
- インタラクティブな設定選択
- 詳細なエラーメッセージとガイダンス

## 互換性への配慮

### 既存ユーザー向け
- 古いパス (`$HOME/.claude-hooks.json`) からの移行手順を文書化
- 環境変数による既存設定の継続利用可能

### 移行スクリプト案
今後作成予定：
```bash
# 既存設定の検出と移行
if [[ -f "$HOME/.claude-hooks.json" ]]; then
    echo "既存の設定ファイルを発見しました"
    echo "新しい場所に移行しますか？"
fi
```

## 今後の拡張予定

### 1. 設定管理の改善
- 設定ファイルのバリデーション
- 設定のバックアップ/復元機能
- 複数環境での設定切り替え

### 2. GUI設定ツール
- Web UI での設定管理
- 設定ウィザード
- リアルタイム設定テスト

### 3. 設定テンプレート
- ユースケース別の設定テンプレート
- 組織向けの標準設定配布
- 設定の継承とオーバーライド

## 使用方法の変更

### セットアップ
```bash
# 新しい方法（推奨）
./config/setup.sh

# 従来の方法も継続サポート
export CLAUDE_HOOKS_CONFIG="$HOME/.claude-hooks.json"
```

### テスト実行
```bash
# デフォルト設定の使用
./test_notifications.sh

# カスタム設定の使用  
CLAUDE_HOOKS_CONFIG="/path/to/config.json" ./test_notifications.sh
```

## 注意事項

### セキュリティ
- 設定ファイルの権限管理の重要性
- Webhook URLの機密性保持
- バックアップファイルの権限設定

### 運用
- 設定変更時のテスト実行推奨
- ログファイルの定期的な確認
- 複数環境での設定の統一性確保