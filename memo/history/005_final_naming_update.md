# 005_final_naming_update.md

## 作業日時
2025-07-03

## タスク
最終的な命名統一: claude-code-hooks-scripts

## 実施内容

### 1. 最終的な命名決定

#### 設定パス
- **最終決定**: `$HOME/.config/claude-code-hooks-scripts/config.json`
- **理由**: 
  - `claude-hooks` でも公式感があるため、より明確に
  - `scripts` を追加してサードパーティツールであることを明示
  - リポジトリ名との統一性確保

#### リポジトリ名
- **現在**: `claude-code-hocks` (typoあり)
- **推奨**: `claude-code-hooks-scripts`
- **統一性**: 設定パスとリポジトリ名を完全に統一

### 2. 更新したファイル

#### 共通ライブラリ
- `lib/common/slack_notifier.sh`: 
  ```bash
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code-hooks-scripts"
  ```

#### セットアップスクリプト
- `config/setup.sh`:
  - 設定パス更新
  - パス例の更新

#### ドキュメント
- `docs/setup.md`: 
  - タイトル変更: "Claude Code Hooks Scripts セットアップガイド"
  - 全パス例の更新
  - リポジトリ参照パスの更新

- `DIRECTORY_STRUCTURE.md`:
  - タイトル更新
  - ディレクトリ構成例の更新
  - 説明文の更新

### 3. 命名の進化

#### 第1段階: `$HOME/.claude-hooks.json`
- 問題: ホームディレクトリの汚染

#### 第2段階: `$HOME/.config/claude-code/hooks.json`
- 問題: 公式ツールと誤解される可能性

#### 第3段階: `$HOME/.config/claude-hooks/config.json`
- 問題: まだ公式感がある

#### 第4段階（最終）: `$HOME/.config/claude-code-hooks-scripts/config.json`
- 解決: 明確にサードパーティスクリプトと分かる

### 4. 統一された命名規則

#### 一貫性の確保
- **リポジトリ名**: `claude-code-hooks-scripts`
- **設定ディレクトリ**: `claude-code-hooks-scripts`
- **ドキュメントタイトル**: "Claude Code Hooks Scripts"
- **設定ファイル**: `config.json`

#### パス例の統一
```bash
# 設定ファイル
$HOME/.config/claude-code-hooks-scripts/config.json

# リポジトリ
/path/to/claude-code-hooks-scripts

# スクリプト
/path/to/claude-code-hooks-scripts/hooks/notification/slack_notify.sh
```

### 5. リポジトリ名変更の推奨

#### 現状の問題
- `claude-code-hocks` にはtypoがある（hooksのつもり）
- 設定パスとの一貫性がない

#### 推奨される変更
```bash
# GitHubでのリポジトリ名変更
old: claude-code-hocks
new: claude-code-hooks-scripts
```

#### 変更の利点
1. **typoの修正**: hocks → hooks-scripts
2. **一貫性**: 設定パスとリポジトリ名の統一
3. **明確性**: サードパーティスクリプトであることの明示
4. **将来性**: 公式ツールとのバッティング回避

### 6. 互換性の維持

#### 環境変数による柔軟性
```bash
# カスタム設定パス
export CLAUDE_HOOKS_CONFIG="/custom/path/config.json"

# 既存設定の継続利用
export CLAUDE_HOOKS_CONFIG="$HOME/.claude-hooks.json"
```

#### 移行の簡素化
- セットアップスクリプトによる自動設定
- 詳細なドキュメント提供
- 既存設定の継続サポート

### 7. ユーザーへの影響

#### 新規ユーザー
- セットアップスクリプトで自動設定
- 明確な命名で混乱を回避
- 統一されたドキュメント

#### 既存ユーザー
- 環境変数での継続利用可能
- 段階的な移行をサポート
- バックワード互換性の確保

### 8. 今後のアクション

#### 推奨される次のステップ
1. **リポジトリ名の変更**: GitHubでのリネーム
2. **README.md作成**: プロジェクト概要の明記
3. **移行ガイド**: 既存ユーザー向けの移行手順
4. **テスト更新**: 新しいパスでの動作確認

#### 長期的な計画
- 他のプラットフォーム（Discord、Teams）対応
- 設定管理ツールの拡張
- コミュニティフィードバックの収集

## まとめ

この最終的な命名統一により、以下を達成：

1. ✅ **公式ツールとの明確な区別**
2. ✅ **一貫した命名規則の適用**
3. ✅ **サードパーティツールの明示**
4. ✅ **将来的なバッティングリスクの除去**
5. ✅ **互換性の維持**

`claude-code-hooks-scripts` という名前により、このプロジェクトの性質と目的が明確に伝わるようになりました。