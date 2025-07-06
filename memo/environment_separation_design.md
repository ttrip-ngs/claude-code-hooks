# 開発・本番環境分離設計案

## 🎯 問題の整理

開発用ディレクトリと本番用ディレクトリでgit cloneして運用する際の環境変数競合問題を解決する必要があります。

## 💡 解決策の比較

### Option 1: 環境変数の名前空間分離（推奨）
```bash
# 開発環境
export CLAUDE_HOOKS_DEV_SLACK_WEBHOOK_URL="..."
export CLAUDE_HOOKS_DEV_SLACK_CHANNEL="..."

# 本番環境
export CLAUDE_HOOKS_PROD_SLACK_WEBHOOK_URL="..."
export CLAUDE_HOOKS_PROD_SLACK_CHANNEL="..."
```

### Option 2: 設定ファイルベース管理（最推奨）
```bash
# 各ディレクトリに独立した設定ファイル
~/dev/claude-code-hocks/.env
~/prod/claude-code-hooks-scripts/.env
```

### Option 3: CLAUDE_HOOKS_ENV による環境切り替え
```bash
export CLAUDE_HOOKS_ENV="development"  # または "production"
```

### Option 4: ディレクトリベース自動判定
```bash
# スクリプトが自身のパスから環境を自動判定
/home/user/dev/claude-code-hocks/     → development
/home/user/prod/claude-code-hooks/    → production
```

## 🏆 推奨解決策：設定ファイルベース管理

### 設計方針
1. **各ディレクトリに独立した設定ファイル**
2. **環境変数はフォールバック**
3. **明示的な環境指定も可能**

### ディレクトリ構成例
```
# 開発環境
~/dev/claude-code-hocks/
├── .env                          # 開発用設定
├── config/
│   ├── development.env           # 開発環境設定
│   └── production.env            # 本番環境設定（テンプレート）
└── hooks/

# 本番環境
~/prod/claude-code-hooks-scripts/
├── .env                          # 本番用設定
├── config/
│   ├── development.env           # 開発環境設定（テンプレート）
│   └── production.env            # 本番環境設定
└── hooks/
```

### 設定ファイル形式
```bash
# .env (ディレクトリルートの設定ファイル)
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
SLACK_CHANNEL="YOUR_USER_ID"
SLACK_ICON=":robot_face:"
SLACK_USERNAME="Claude Code [DEV]"
ENVIRONMENT="development"
```

### 設定読み込み優先順位
1. `CLAUDE_HOOKS_CONFIG` 環境変数で指定されたファイル
2. `$PROJECT_ROOT/.env`
3. `$PROJECT_ROOT/config/$ENVIRONMENT.env`
4. 既存の環境変数
5. デフォルト値

## 🔧 実装案

### 共通ライブラリの修正
```bash
# lib/config_loader.sh
load_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local project_root="$(cd "$script_dir/../.." && pwd)"
    local environment="${CLAUDE_HOOKS_ENV:-development}"
    
    # 設定ファイルの優先順位
    local config_files=(
        "$CLAUDE_HOOKS_CONFIG"                    # 明示的指定
        "$project_root/.env"                      # プロジェクトルート
        "$project_root/config/$environment.env"   # 環境別設定
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            source "$config_file"
            echo "[INFO] 設定ファイルを読み込みました: $config_file" >&2
            break
        fi
    done
}
```

### スクリプトでの使用例
```bash
#!/bin/bash
# hooks/stop/slack.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/config_loader.sh"
source "$SCRIPT_DIR/../../lib/slack_messenger.sh"

# 設定読み込み
load_config

# 以降は通常通り
main() {
    # ...
}
```

## 📁 設定ファイルテンプレート

### 開発環境用 (.env.development)
```bash
# 開発環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/DEV/WEBHOOK/URL"
SLACK_CHANNEL="#development-alerts"
SLACK_USERNAME="Claude Code [DEV]"
SLACK_ICON=":construction:"
ENVIRONMENT="development"
LOG_LEVEL="debug"
```

### 本番環境用 (.env.production)
```bash
# 本番環境設定
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/PROD/WEBHOOK/URL"
SLACK_CHANNEL="YOUR_USER_ID"
SLACK_USERNAME="Claude Code"
SLACK_ICON=":robot_face:"
ENVIRONMENT="production"
LOG_LEVEL="info"
```

## 🚀 デプロイメント手順

### 1. 本番環境へのデプロイ
```bash
# 本番ディレクトリに移動
cd ~/prod/
git clone <repository-url> claude-code-hooks-scripts
cd claude-code-hooks-scripts

# 本番用設定ファイルを作成
cp config/production.env.template .env
nano .env  # 本番用設定を編集

# Claude Code設定
mkdir -p ~/.claude
cat > ~/.claude/settings.toml << EOF
[[hooks]]
event = "Stop"
command = "$HOME/prod/claude-code-hooks-scripts/hooks/stop/slack.sh"
EOF
```

### 2. 開発環境での作業継続
```bash
# 開発ディレクトリで作業継続
cd ~/dev/claude-code-hocks

# 開発用設定（既存）
# .env ファイルがすでに開発用設定になっている
```

### 3. 環境の明示的切り替え
```bash
# 特定の環境を明示的に指定
export CLAUDE_HOOKS_ENV="production"
./hooks/stop/slack.sh

# または設定ファイルを直接指定
export CLAUDE_HOOKS_CONFIG="/path/to/specific/config.env"
./hooks/stop/slack.sh
```

## 🔒 セキュリティ考慮事項

### 1. 設定ファイルの権限
```bash
# .envファイルの権限を制限
chmod 600 .env
chmod 600 config/*.env
```

### 2. Gitでの管理
```bash
# .gitignore に追加
echo ".env" >> .gitignore
echo "config/local.env" >> .gitignore

# テンプレートファイルのみコミット
git add config/development.env.template
git add config/production.env.template
```

### 3. 設定検証
```bash
# 設定ファイルの検証スクリプト
./scripts/validate-config.sh
```

## 💡 その他の利点

### 1. チーム開発対応
- 各開発者が独自の設定を持てる
- 共通のテンプレートで設定の一貫性を保持

### 2. 複数環境対応
- staging, testing環境も簡単に追加可能
- 環境ごとの設定継承

### 3. デバッグ支援
- 設定ファイルの読み込み状況がログで確認可能
- 環境変数の上書き関係が明確

この設計により、開発・本番環境の完全分離と、柔軟な設定管理が実現できます。