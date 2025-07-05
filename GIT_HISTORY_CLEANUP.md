# 🚨 Git履歴機密情報削除手順

**緊急対応**: コミット `597c1d1` から機密情報 (`test-config.json`) を完全削除

## ⚠️ 重要な注意事項

**この操作は不可逆的です**。実行前に必ずバックアップを取得してください。

```bash
# バックアップ作成
git clone . ../claude-code-hocks-backup
```

## 🔧 方法1: git filter-repo（推奨）

### 1. git filter-repo のインストール

```bash
# Ubuntu/Debian
sudo apt-get install git-filter-repo

# macOS
brew install git-filter-repo

# pip経由
pip install git-filter-repo
```

### 2. 機密ファイルの完全削除

```bash
# プロジェクトルートで実行
cd /home/takuyatakaira/Dev/claude-code-hocks

# test-config.json を履歴から完全削除
git filter-repo --path test-config.json --invert-paths

# 実行結果確認
git log --oneline --all --grep="test-config"
```

## 🔧 方法2: git filter-branch（従来方式）

```bash
# プロジェクトルートで実行
cd /home/takuyatakaira/Dev/claude-code-hocks

# 全ブランチから test-config.json を削除
git filter-branch --force --index-filter \
    'git rm --cached --ignore-unmatch test-config.json' \
    --prune-empty --tag-name-filter cat -- --all

# 一時ファイルの削除
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## 🔍 削除確認

```bash
# 1. ファイルが履歴に存在しないことを確認
git log --all --full-history -- test-config.json

# 2. 機密情報検索（何も出力されないことを確認）
git log --all -p | grep -i "hooks.slack.com" || echo "機密情報が削除されました"

# 3. リポジトリサイズの確認
du -sh .git/
```

## 📝 リモートリポジトリへの反映

**注意**: この操作によりリモートリポジトリの履歴が書き換えられます。

```bash
# 強制プッシュ（全ブランチ）
git push origin --force --all

# タグも強制プッシュ
git push origin --force --tags
```

## 🔒 追加セキュリティ対策

### 1. 機密情報の無効化

```bash
# Slackワークスペースで以下を実行:
# 1. 該当Webhook URLの無効化
# 2. 新しいWebhook URLの生成
# 3. 新しいURLで設定ファイルを更新
```

### 2. 今後の予防策

```bash
# Pre-commitフックの有効化
cp scripts/security_scan.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 定期的なスキャン実行
./scripts/security_scan.sh --git
```

## 📊 実行チェックリスト

- [ ] バックアップの作成
- [ ] git filter-repo のインストール
- [ ] 機密ファイルの削除実行
- [ ] 削除確認の実行
- [ ] Slack Webhook URLの無効化
- [ ] 新しいWebhook URLの生成
- [ ] リモートリポジトリへの反映
- [ ] チーム内への通知
- [ ] セキュリティスキャンの実行

## 🚨 緊急時の対応

実行中に問題が発生した場合:

```bash
# 操作の中断
Ctrl+C

# バックアップからの復旧
cd ..
rm -rf claude-code-hocks
cp -r claude-code-hocks-backup claude-code-hocks
cd claude-code-hocks
```

## 📞 サポート

質問がある場合は、この手順を実行前に以下で相談してください:
- セキュリティチーム
- Git管理者
- プロジェクトリーダー

---

**⚠️ この文書は機密情報を含むため、関係者のみで共有してください。**