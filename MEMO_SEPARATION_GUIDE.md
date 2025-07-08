# 開発履歴の分離管理ガイド

## 🎯 目的
開発履歴（memo/）をprivateリポジトリで管理し、メインコードはpublicで公開する

## 📋 実装手順

### 1. Privateリポジトリの作成
```bash
# GitHubで新しいprivateリポジトリを作成
# 例: claude-code-hocks-memo (PRIVATE)
```

### 2. 現在のmemoディレクトリを移行

```bash
# 1. memoディレクトリを別の場所にコピー
cp -r memo ../memo-backup

# 2. Git履歴からmemoディレクトリを削除
git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch memo' \
  --prune-empty --tag-name-filter cat -- --all

# 3. クリーンアップ
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 4. .gitignoreに追加
echo "memo/" >> .gitignore
git add .gitignore
git commit -m "chore: memoディレクトリをgitignoreに追加"
```

### 3. Privateリポジトリのセットアップ

```bash
# 別ディレクトリで実行
cd ..
mkdir claude-code-hocks-memo
cd claude-code-hocks-memo
git init

# memoファイルをコピー
cp -r ../memo-backup/* .

# 初回コミット
git add .
git commit -m "Initial commit: 開発履歴の移行"

# リモート追加
git remote add origin git@github.com:YOUR_USERNAME/claude-code-hocks-memo.git
git push -u origin main
```

### 4. サブモジュールとして追加（オプション）

開発者のローカル環境でのみ：
```bash
cd claude-code-hocks
git submodule add git@github.com:YOUR_USERNAME/claude-code-hocks-memo.git memo
git config submodule.memo.update none  # 自動更新を無効化
```

## 🔧 代替案

### 案A: 暗号化アーカイブ
```bash
# memoディレクトリを暗号化してコミット
tar -czf - memo/ | openssl enc -aes-256-cbc -salt -out memo.tar.gz.enc
git add memo.tar.gz.enc
echo "memo/" >> .gitignore
```

### 案B: 完全分離
- publicリポジトリ: コードのみ
- privateリポジトリ: 開発履歴のみ
- 連携なし（最もシンプル）

### 案C: GitHub Wiki（Private）
- リポジトリ設定でWikiをprivateに設定可能
- 開発履歴をWikiで管理

## 📊 各案の比較

| 方式 | セキュリティ | 管理の容易さ | アクセス性 |
|------|------------|------------|----------|
| サブモジュール | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| 暗号化 | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| 完全分離 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Wiki | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## 🚨 注意事項

1. **Git履歴の削除は不可逆的**
   - 必ずバックアップを作成
   - チームメンバーへの通知が必要

2. **既存のfork/cloneへの影響**
   - 履歴書き換え後は再クローンが必要
   - 既存のPRは影響を受ける可能性

3. **サブモジュールの注意点**
   - publicリポジトリのREADMEで言及しない
   - .gitmodulesファイルはpublicになる

## 🎯 推奨構成

```
claude-code-hocks/          # PUBLIC
├── hooks/
├── lib/
├── scripts/
├── docs/
├── config/
├── .gitignore             # memo/を除外
└── README.md

claude-code-hocks-memo/     # PRIVATE
├── history/
│   ├── 001_initial_setup.md
│   ├── 002_slack_notification_implementation.md
│   └── ...
├── design/
└── analysis/
```

## 📝 実行チェックリスト

- [ ] メインリポジトリのバックアップ作成
- [ ] memoディレクトリのバックアップ作成
- [ ] privateリポジトリの作成
- [ ] Git履歴からmemoを削除
- [ ] privateリポジトリへmemoを移行
- [ ] .gitignoreの更新
- [ ] チームへの通知
- [ ] ドキュメントの更新
