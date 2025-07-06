# 環境分離システム実装 - 開発履歴 009

**作成日**: 2025-07-05 08:35  
**担当**: Claude Code Assistant  

## 📋 実装概要

開発・本番環境での環境変数競合問題を解決するため、設定ファイルベースの環境分離システムを実装しました。

## 🎯 解決した問題

### 問題の背景
- 開発用ディレクトリ（`~/dev/claude-code-hocks`）と本番用ディレクトリの分離運用
- git cloneによる複数環境での環境変数競合
- 設定の重複管理と人的ミスのリスク

### 採用した解決策
**設定ファイルベース管理 + 自動環境判定**による完全分離

## 🔧 主な実装内容

### 1. 設定ファイル読み込みシステム

**ファイル**: `lib/config_loader.sh`

#### 主要機能:
- **設定読み込み優先順位**:
  1. `$CLAUDE_HOOKS_CONFIG` - 明示的指定ファイル
  2. `$PROJECT_ROOT/.env` - プロジェクト直下設定
  3. `$PROJECT_ROOT/config/$ENVIRONMENT.env` - 環境別設定
  4. 環境変数
  5. デフォルト値

- **自動環境判定**:
  - ディレクトリパス解析による環境自動判定
  - `/dev/`, `/development/` → development
  - `/prod/`, `/production/` → production
  - デフォルト → development

- **設定検証**: 必須設定の自動チェック
- **セキュリティ**: ファイル権限の確認

#### 技術的特徴:
```bash
# 呼び出し元スクリプトからの相対パス計算
local caller_script="${BASH_SOURCE[1]}"
local script_dir="$(cd "$(dirname "$caller_script")" && pwd)"
local project_root="$(cd "$script_dir/../.." && pwd)"

# 環境の自動判定
if echo "$project_root" | grep -q "/dev/\|/development/"; then
    environment="development"
elif echo "$project_root" | grep -q "/prod/\|/production/"; then
    environment="production"
fi
```

### 2. 環境別設定テンプレート

**ファイル**:
- `config/development.env.template`
- `config/production.env.template`
- `.env.example`

#### 設定項目:
```bash
# 共通設定
SLACK_WEBHOOK_URL="..."
SLACK_CHANNEL="..."
SLACK_USERNAME="..."
SLACK_ICON="..."
ENVIRONMENT="..."
LOG_LEVEL="..."
```

#### 環境別差分:
| 項目 | Development | Production |
|------|-------------|------------|
| Username | "Claude Code [DEV]" | "Claude Code" |
| Icon | ":construction:" | ":robot_face:" |
| Log Level | "debug" | "info" |
| Channel | "#development-alerts" | "UJM1V2AAH" |

### 3. 自動デプロイメントシステム

**ファイル**: `scripts/deploy.sh`

#### 主要機能:
- **前提条件チェック**: git, jq, curl等の依存関係確認
- **安全性確認**: 未コミット変更の検出
- **自動デプロイ**: リポジトリクローンと設定ファイル生成
- **検証機能**: デプロイ後の整合性確認
- **ドライラン**: `--dry-run`による事前確認

#### 使用例:
```bash
# 本番環境へのデプロイ
./scripts/deploy.sh production ~/prod/claude-code-hooks-scripts

# ドライラン実行
./scripts/deploy.sh --dry-run production ~/prod/claude-code-hooks-scripts
```

### 4. 既存スクリプトの統合

**修正ファイル**:
- `lib/slack_messenger.sh`
- `hooks/stop/slack.sh`
- `hooks/notification/slack.sh`
- `hooks/subagent-stop/slack.sh`

#### 統合内容:
```bash
# 各Hookスクリプトに設定読み込みを追加
source "$SCRIPT_DIR/../../lib/config_loader.sh"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

# slack_messenger.shに自動設定読み込み
if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    load_config
fi
```

## 📁 新しいディレクトリ構成

```
claude-code-hooks-scripts/
├── lib/
│   ├── config_loader.sh         # 設定読み込みシステム
│   └── slack_messenger.sh       # Slack送信（設定統合済み）
├── config/
│   ├── development.env.template # 開発環境テンプレート
│   ├── production.env.template  # 本番環境テンプレート
│   └── staging.env.template     # ステージング環境テンプレート（将来用）
├── scripts/
│   └── deploy.sh                # 自動デプロイスクリプト
├── .env.example                 # 設定例ファイル
├── .env                         # 実際の設定（開発用、.gitignore対象）
├── PRODUCTION_DEPLOYMENT.md     # デプロイメント手順書
└── .gitignore                   # 機密設定ファイル除外
```

## 🚀 デプロイメントフロー

### 1. 開発環境（既存）
```bash
# 開発ディレクトリでの作業
cd ~/dev/claude-code-hocks

# 自動的にdevelopment環境として動作
./hooks/stop/slack.sh "開発作業" "完了"
# → "Claude Code [DEV]" で通知
```

### 2. 本番環境（新規）
```bash
# 自動デプロイ
./scripts/deploy.sh production ~/prod/claude-code-hooks-scripts

# 本番環境での動作
cd ~/prod/claude-code-hooks-scripts
./hooks/stop/slack.sh "本番作業" "完了"
# → "Claude Code" で通知
```

### 3. Claude Code設定

**開発環境用**:
```toml
[[hooks]]
event = "Stop"
command = "/home/your-username/dev/claude-code-hocks/hooks/stop/slack.sh"
```

**本番環境用**:
```toml
[[hooks]]
event = "Stop"
command = "/home/your-username/prod/claude-code-hooks-scripts/hooks/stop/slack.sh"
```

## 🔒 セキュリティ実装

### 1. ファイル権限管理
```bash
# 設定ファイルの権限制限
chmod 600 .env
chmod 600 config/*.env
```

### 2. Git管理
```bash
# .gitignoreに機密情報を除外
.env
config/local.env
```

### 3. 設定検証
```bash
# 必須設定の自動チェック
validate_required_config() {
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        missing_config+=("SLACK_WEBHOOK_URL")
    fi
}
```

## 🧪 テスト結果

### 環境分離テスト
```bash
# 開発環境でのテスト
cd ~/dev/claude-code-hocks
./hooks/notification/slack.sh info "開発環境テスト"
# → 自動的にdevelopment設定で実行

# 本番環境でのテスト（デプロイ後）
cd ~/prod/claude-code-hooks-scripts
./hooks/notification/slack.sh info "本番環境テスト"
# → 自動的にproduction設定で実行
```

### 設定読み込みテスト
```
[CONFIG] 2025-07-05 08:35:00 環境: development
[CONFIG] 2025-07-05 08:35:00 プロジェクトルート: /home/takuyatakaira/dev/claude-code-hocks
[CONFIG] 2025-07-05 08:35:00 設定ファイルを読み込みました: /home/takuyatakaira/dev/claude-code-hocks/.env
[CONFIG] 2025-07-05 08:35:00 設定検証が完了しました
```

## 💡 技術的成果

### 設計原則の実現
1. **DRY原則**: 設定の重複排除
2. **設定の分離**: 環境ごとの独立した設定管理
3. **自動化**: デプロイメントの自動化
4. **安全性**: 設定検証とセキュリティ確保

### 拡張性の確保
- 新環境（staging等）の簡単追加
- カスタム設定ファイルパスの対応
- 環境変数による柔軟な制御

### 運用性の向上
- ワンコマンドデプロイメント
- 自動環境判定による人的ミス防止
- 詳細なログ出力による運用支援

## 🎯 解決効果

### Before（問題）
- 環境変数の競合リスク
- 設定の手動管理
- デプロイメントの複雑性
- 環境間の設定ミス

### After（解決）
- ✅ 完全な環境分離
- ✅ 自動設定管理
- ✅ ワンコマンドデプロイ
- ✅ 設定検証・安全性確保

## 📚 ドキュメント整備

### 作成ドキュメント
1. **PRODUCTION_DEPLOYMENT.md**: 詳細なデプロイメント手順
2. **環境設定テンプレート**: 各環境の標準設定
3. **設定例ファイル**: `.env.example`による設定ガイド

### 更新ドキュメント
1. **SETUP_GUIDE.md**: 設定ファイルベース管理に対応
2. **QUICK_START.md**: 新しい設定方法に対応

この実装により、開発・本番環境の完全分離と安全な運用管理が実現され、Claude Code Hooksプロジェクトの運用品質が大幅に向上しました。