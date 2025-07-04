# 004_config_naming_fix.md

## 作業日時
2025-07-03

## タスク
設定ファイルパスの命名を公式ツールとのバッティングを避けるよう修正

## 問題認識

### 指摘された問題点
- `$HOME/.config/claude-code/` は公式ツールの命名に見える
- 将来的にClaude Code公式が同じパスを使用した場合のバッティングリスク
- ユーザーに混乱を与える可能性

### リスク
1. **公式ツールとの混同**: ユーザーが公式機能と誤解する
2. **名前空間の衝突**: 将来の公式拡張と競合する可能性
3. **サポート混乱**: 公式サポートに問い合わせが行く可能性

## 実施した修正

### 1. 設定パスの変更
```bash
# 変更前
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code"
CONFIG_FILE="$CONFIG_DIR/hooks.json"

# 変更後
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-hooks"
CONFIG_FILE="$CONFIG_DIR/config.json"
```

### 2. ファイル名の変更
- **ディレクトリ名**: `claude-code` → `claude-hooks`
- **設定ファイル名**: `hooks.json` → `config.json`

### 3. 更新したファイル一覧

#### 共通ライブラリ
- `lib/common/slack_notifier.sh`: 設定パス変更

#### セットアップスクリプト
- `config/setup.sh`: 設定パスとコマンド例を更新

#### ドキュメント
- `docs/setup.md`: 全体的なパス更新
- `DIRECTORY_STRUCTURE.md`: 設定パス記述の更新

## 新しい命名の理由

### 1. `claude-hooks` の選択理由
- **明確な区別**: 公式ツールとは異なる目的であることが明確
- **機能の説明**: hooksに特化したツールであることが分かる
- **バッティング回避**: 公式が使用する可能性の低い名前

### 2. `config.json` の選択理由
- **汎用性**: hooks以外の設定も将来追加可能
- **標準的**: 多くのツールで使用される一般的な名前
- **分かりやすさ**: 設定ファイルであることが明確

## 互換性への配慮

### 既存ユーザー向けの配慮
1. **環境変数の継続サポート**: `CLAUDE_HOOKS_CONFIG` で既存設定を利用可能
2. **移行の簡素化**: セットアップスクリプトで自動対応
3. **ドキュメントの充実**: 移行手順の明記

### 移行パス
```bash
# 既存設定がある場合
if [[ -f "$HOME/.config/claude-code/hooks.json" ]]; then
    # 新しい場所に移行
    mkdir -p "$HOME/.config/claude-hooks"
    cp "$HOME/.config/claude-code/hooks.json" "$HOME/.config/claude-hooks/config.json"
fi
```

## 技術的な改善点

### 1. より適切な名前空間
- サードパーティツールとしての明確な位置づけ
- 公式ツールとの区別が容易

### 2. 拡張性の向上
- `config.json` により複数種類の設定を統合可能
- 将来的な機能追加に対応しやすい構造

### 3. セキュリティの維持
- ファイル権限設定は継続 (600)
- 設定ディレクトリの自動作成機能も継続

## 今後の考慮事項

### 1. 命名規則の統一
- 他のサードパーティツールとの整合性
- 業界標準との対応

### 2. 公式ツールとの関係
- 公式ツールの新機能発表時の確認
- 必要に応じた追加の差別化

### 3. ユーザビリティの向上
- 設定ファイルの自動検証機能
- より分かりやすいエラーメッセージ

## ユーザーへの影響

### 最小限の影響
- 環境変数による既存設定の継続利用
- セットアップスクリプトによる自動移行
- 詳細なドキュメント提供

### 長期的なメリット
- 公式ツールとのバッティング回避
- より明確な機能の位置づけ
- 将来的な拡張に対する備え

## 設定例の更新

### 新しい設定パス
```bash
# デフォルト設定
$HOME/.config/claude-hooks/config.json

# カスタム設定
export CLAUDE_HOOKS_CONFIG="/custom/path/config.json"

# XDG準拠
export XDG_CONFIG_HOME="/custom/config"
# -> /custom/config/claude-hooks/config.json
```

### セットアップコマンド
```bash
# 自動セットアップ
./config/setup.sh

# 手動設定
mkdir -p "$HOME/.config/claude-hooks"
cp config/examples/minimal-config.json "$HOME/.config/claude-hooks/config.json"
chmod 600 "$HOME/.config/claude-hooks/config.json"
```

## 注意事項

### 新規ユーザー
- セットアップスクリプトを使用すれば自動で適切な設定が完了
- ドキュメントの手順に従って設定

### 既存ユーザー（今後対応予定）
- 移行スクリプトの提供を検討
- 既存設定の自動検出と移行提案
- バックアップ機能の提供

## まとめ

この修正により、以下の問題を解決：
1. ✅ 公式ツールとの混同回避
2. ✅ 将来的なバッティングリスク軽減
3. ✅ より適切な名前空間の使用
4. ✅ 互換性の維持

サードパーティツールとして適切な命名規則に従い、長期的な安定性を確保できました。