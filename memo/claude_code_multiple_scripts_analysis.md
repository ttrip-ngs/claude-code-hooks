# Claude Code Hooks 複数スクリプト実行分析

## 📋 調査結果：Claude Code Hooksでの複数スクリプト登録

### ✅ **結論：YES - STOPイベントに複数スクリプトを登録可能**

Claude Code Hooksの公式仕様では、1つのイベントに対して複数のスクリプトを登録し、**並列実行**することが可能です。

## 🔧 設定方法

### 基本的な設定形式（settings.toml）

```toml
# 複数のHookを同一イベントに登録
[[hooks]]
event = "Stop"
command = "/path/to/script1.sh"

[[hooks]]
event = "Stop"
command = "/path/to/script2.sh"

[[hooks]]
event = "Stop"
command = "/path/to/script3.sh"
```

### より詳細な設定例

```toml
# Slack通知
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack_notify.sh"

# メール通知
[[hooks]]
event = "Stop"
command = "/path/to/email_notification.sh"

# ログ記録
[[hooks]]
event = "Stop"
command = "/path/to/log_session.sh"

# Git自動コミット
[[hooks]]
event = "Stop"
command = "/path/to/auto_commit.sh"

# 環境クリーンアップ
[[hooks]]
event = "Stop"
command = "/path/to/cleanup.sh"
run_in_background = true
```

## ⚡ 実行特性

### 1. **並列実行**
- **デフォルト動作**: 複数のHookは**並列実行**される
- **キーワード**: "All matching hooks run in parallel"
- **利点**: 高速な処理、独立した処理の同時実行

### 2. **バックグラウンド実行**
```toml
[[hooks]]
event = "Stop"
command = "long_running_task.sh"
run_in_background = true  # バックグラウンドで実行
```

### 3. **タイムアウト制御**
- **デフォルト**: 60秒
- **カスタマイズ可能**: 各Hookに個別設定

## 🛠️ エラーハンドリング

### Exit Code による制御
- **Exit Code 0**: 正常終了
- **Exit Code 1**: エラー（他のHookの実行には影響しない）
- **Exit Code 2**: **Blocking error**（重要なエラー、処理停止の可能性）

### 独立実行
- 1つのスクリプトの失敗が他のスクリプトの実行を妨げない
- 各スクリプトは独立してエラーハンドリングを行う

## 📊 現在の実装との比較

### 我々のプロジェクトの状況
```bash
# 現在: 単一スクリプトでSlack通知のみ
./hooks/stop/slack_notify.sh

# Claude Code Hooks設定では:
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack_notify.sh"
```

### 拡張可能性
Claude Code Hooks側で複数登録をサポートしているため、我々のプロジェクトも以下のように拡張可能：

```toml
# 複数の独立したスクリプトとして展開
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack_notify.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/email_notify.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/file_logger.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/git_commit.sh"
```

## 🎯 実装戦略の選択肢

### Option 1: Claude Code Hooks側で複数登録
**利点**:
- 各スクリプトが完全に独立
- 並列実行による高速化
- 個別のエラーハンドリング

**実装例**:
```toml
[[hooks]]
event = "Stop"
command = "/path/to/slack_script.sh"

[[hooks]]
event = "Stop"
command = "/path/to/email_script.sh"
```

### Option 2: 単一スクリプト内でプロセッサー機構
**利点**:
- 設定の一元管理
- 処理順序の制御
- 共通ライブラリの活用

**実装例**:
```toml
[[hooks]]
event = "Stop"
command = "/path/to/process_manager.sh"
```

## 💡 推奨アプローチ

### **ハイブリッド戦略**
1. **単純な処理**: Claude Code Hooks側で複数登録
2. **複雑な処理**: プロセッサー機構で統合管理

### 実装例
```toml
# 軽量で独立性が重要な処理
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/slack_notify.sh"

[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/quick_log.sh"

# 複雑で協調が必要な処理
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hooks-scripts/hooks/stop/complex_processor.sh"
```

## 🔍 環境変数の共有

### 利用可能な環境変数（全スクリプトで共通）
- `$CLAUDE_SESSION_ID`
- `$CLAUDE_FILE_PATHS`
- `$CLAUDE_NOTIFICATION`
- `$CLAUDE_TOOL_OUTPUT`

### JSON入力（stdin経由）
```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../session.jsonl"
}
```

## ✅ 結論

**Claude Code HooksはSTOPイベントに複数スクリプトの登録が可能**であり、以下の特徴を持ちます：

1. **並列実行**: 高速な処理
2. **独立性**: スクリプト間の相互影響なし
3. **柔軟性**: バックグラウンド実行、タイムアウト制御
4. **拡張性**: 我々のプロジェクトとの親和性が高い

これにより、Slack通知以外の多様な処理（メール、ログ、Git操作、クリーンアップ等）を効果的に組み合わせることができます。