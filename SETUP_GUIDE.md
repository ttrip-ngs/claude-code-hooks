# Claude Code Hooks 登録手順

## 📋 前提条件

### 1. 必要なソフトウェア
- **Claude Code**: 最新版がインストールされていること
- **jq**: JSONパース用（`sudo apt install jq` または `brew install jq`）
- **curl**: HTTP通信用（通常はプリインストール）
- **git**: リポジトリ情報取得用（オプション）

### 2. Slack Webhook URL の取得
1. Slackワークスペースの管理画面にアクセス
2. 「アプリ」→「Incoming Webhooks」を選択
3. 新しいWebhookを作成してURLをコピー

## 🚀 Step 1: プロジェクトのダウンロード

```bash
# プロジェクトをクローン
git clone <repository-url> claude-code-hooks-scripts
cd claude-code-hooks-scripts

# または既存のプロジェクトディレクトリに移動
cd /path/to/claude-code-hocks
```

## ⚙️ Step 2: 環境変数の設定

### 方法A: 環境設定スクリプトを使用（推奨）
```bash
# 環境設定スクリプトを実行
source examples/environment-setup.sh

# Slack Webhook URLを設定（必須）
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# チャンネルを設定（デフォルト: UJM1V2AAH）
export SLACK_CHANNEL="UJM1V2AAH"  # または "#your-channel"
```

### 方法B: 手動設定
```bash
# 必須設定
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_CHANNEL="UJM1V2AAH"

# オプション設定
export SLACK_ICON=":robot_face:"
export SLACK_USERNAME="Claude Code"
```

### 方法C: 永続化設定
```bash
# ~/.bashrc または ~/.zshrc に追加
echo 'export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"' >> ~/.bashrc
echo 'export SLACK_CHANNEL="UJM1V2AAH"' >> ~/.bashrc
source ~/.bashrc
```

## 🔧 Step 3: Claude Code設定ファイルの作成

### 設定ファイルの場所
```bash
# Claude Code設定ファイル
~/.claude/settings.toml
```

### 基本設定の追加
```bash
# 設定ディレクトリを作成（存在しない場合）
mkdir -p ~/.claude

# プロジェクトのパスを取得
PROJECT_PATH=$(pwd)
echo "プロジェクトパス: $PROJECT_PATH"
```

### settings.toml の編集
```bash
# エディタで設定ファイルを開く
nano ~/.claude/settings.toml
# または
code ~/.claude/settings.toml
```

### 設定内容の追加
```toml
# Claude Code Hooks 設定
# プロジェクトパスを実際のパスに置き換えてください

# Stop Hook: 作業完了時の通知
[[hooks]]
event = "Stop"
command = "/home/takuyatakaira/Dev/claude-code-hocks/hooks/stop/slack.sh"

# Notification Hook: 各種通知
[[hooks]]
event = "Notification"
command = "/home/takuyatakaira/Dev/claude-code-hocks/hooks/notification/slack.sh"

# SubagentStop Hook: サブエージェント完了時の通知
[[hooks]]
event = "SubagentStop"
command = "/home/takuyatakaira/Dev/claude-code-hocks/hooks/subagent-stop/slack.sh"
```

## 🧪 Step 4: テスト実行

### 1. 依存関係チェック
```bash
# 環境設定スクリプトで依存関係を確認
source examples/environment-setup.sh
```

### 2. 個別スクリプトテスト
```bash
# Notification Hook テスト
./hooks/notification/slack.sh info "テストメッセージ"

# Stop Hook テスト
./hooks/stop/slack.sh "テスト作業" "テスト完了" "1分"

# SubagentStop Hook テスト
./hooks/subagent-stop/slack.sh "テストタスク" "タスク完了" "30秒"
```

### 3. Claude Code経由のテスト
```bash
# Claude Codeでコマンドを実行してHookが動作することを確認
claude-code --help  # 何らかのコマンドを実行してHookをトリガー
```

## 📱 Step 5: 設定の確認

### 1. 設定ファイルの構文チェック
```bash
# TOMLファイルの構文確認（toml-cliがある場合）
toml verify ~/.claude/settings.toml

# または手動確認
cat ~/.claude/settings.toml
```

### 2. 環境変数の確認
```bash
# 設定されている環境変数を確認
echo "SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL:-(未設定)}"
echo "SLACK_CHANNEL: ${SLACK_CHANNEL:-(未設定)}"
echo "SLACK_ICON: ${SLACK_ICON:-(未設定)}"
echo "SLACK_USERNAME: ${SLACK_USERNAME:-(未設定)}"
```

### 3. スクリプトの実行権限確認
```bash
# 実行権限があることを確認
ls -la hooks/*/slack.sh
```

## 🔄 Step 6: 実際のClaude Code使用

### 1. 通常の作業でテスト
```bash
# Claude Codeで何らかの作業を実行
claude-code "簡単なテストファイルを作成してください"
# → 作業完了時にSlack通知が送信される
```

### 2. 各Hookの動作確認
- **Notification Hook**: Claude Codeが確認や警告を出した時
- **Stop Hook**: Claude Codeのセッションが終了した時
- **SubagentStop Hook**: Task toolが実行された時

## 🎛️ 高度な設定（オプション）

### 複数スクリプトの登録
```toml
# 複数の処理を並列実行
[[hooks]]
event = "Stop"
command = "/path/to/claude-code-hocks/hooks/stop/slack.sh"

[[hooks]]
event = "Stop"
command = "/path/to/other-script.sh"
run_in_background = true
```

### 条件付き実行
```toml
# 特定のツールでのみ実行
[[hooks]]
event = "PostToolUse"
matcher = "Edit|Write|MultiEdit"
command = "/path/to/claude-code-hocks/hooks/post-tool-use/auto-format.sh"
```

## 🛠️ トラブルシューティング

### よくある問題と解決方法

#### 1. "command not found" エラー
```bash
# スクリプトのパスが正しいか確認
ls -la /path/to/claude-code-hocks/hooks/stop/slack.sh

# 実行権限があるか確認
chmod +x hooks/*/slack.sh
```

#### 2. "SLACK_WEBHOOK_URL が設定されていません" エラー
```bash
# 環境変数が設定されているか確認
echo $SLACK_WEBHOOK_URL

# 再設定
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

#### 3. Slack通知が送信されない
```bash
# Webhook URLが正しいかテスト
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"テストメッセージ"}' \
  "$SLACK_WEBHOOK_URL"

# jqコマンドが利用可能か確認
which jq
```

#### 4. Claude Codeが設定を認識しない
```bash
# 設定ファイルの場所を確認
ls -la ~/.claude/settings.toml

# Claude Codeのバージョン確認
claude-code --version

# 設定の再読み込み（Claude Codeを再起動）
```

## ✅ 設定完了の確認

以下がすべて確認できれば設定完了です：

1. ✅ 環境変数が設定されている
2. ✅ スクリプトが実行可能
3. ✅ Claude Code設定ファイルが正しい
4. ✅ 個別テストでSlack通知が送信される
5. ✅ Claude Code実行時にHookが動作する

## 🚀 次のステップ

設定が完了したら、以下のように活用できます：

- **作業完了通知**: Stop Hookで自動的に作業報告
- **エラー通知**: Notification Hookでリアルタイムアラート
- **進捗追跡**: SubagentStop Hookでタスク完了追跡
- **複数スクリプト**: Claude Code側で複数処理を組み合わせ

Claude Code Hooks Scriptsをお楽しみください！ 🎉