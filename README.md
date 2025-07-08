# Claude Code Hooks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/ttrip-ngs/claude-code-hooks/pulls)

Claude Code（Anthropic社のCLIツール）の作業イベントをフックし、Slack通知を自動送信するシステムです。開発者の作業状況をリアルタイムで把握し、チーム内のコミュニケーションを円滑にします。

## 特徴

- **5分でセットアップ完了** - シンプルな設定で即座に利用開始
- **リアルタイム通知** - Claude Codeの作業状況を即座にSlackへ通知
- **セキュリティ重視** - 機密情報検出・漏洩防止機能を標準搭載
- **環境自動判別** - 開発・本番環境を自動で切り替え
- **カスタマイズ可能** - 柔軟な設定でチームのニーズに対応

## 必要条件

- Bash 4.0以上
- Git
- jq（JSON処理用）
- curl（HTTP通信用）
- Claude Code（インストール済み）
- Slack Webhook URL

## クイックスタート

```bash
# 1. リポジトリをクローン
git clone https://github.com/ttrip-ngs/claude-code-hooks.git
cd claude-code-hooks

# 2. Slack Webhook URLを設定
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# 3. Claude Code設定ファイルを作成
mkdir -p ~/.claude
cat > ~/.claude/settings.toml << 'EOF'
[hooks]
stop = "/path/to/claude-code-hooks/hooks/stop/slack.sh"
notification = "/path/to/claude-code-hooks/hooks/notification/slack.sh"
subagent-stop = "/path/to/claude-code-hooks/hooks/subagent-stop/slack.sh"
EOF

# 4. テスト通知を送信
./hooks/notification/slack.sh info "セットアップ完了！"
```

詳細な手順は [QUICK_START.md](QUICK_START.md) を参照してください。

## プロジェクト構造

```
claude-code-hooks/
├── hooks/              # イベントフックスクリプト
│   ├── notification/   # 通知フック
│   ├── stop/          # 作業完了フック
│   └── subagent-stop/ # サブエージェント完了フック
├── scripts/           # ユーティリティスクリプト
│   ├── deploy.sh      # デプロイメント支援
│   └── security_scan.sh # 機密情報検出
├── config/            # 設定ファイル
├── docs/              # ドキュメント
└── examples/          # サンプルコード
```

## 主な機能

### 1. イベント通知
- **作業完了通知**: Claude Codeの作業終了時に自動通知
- **エラー通知**: エラー発生時の即座の通知
- **進捗通知**: 長時間作業の進捗状況を定期通知

### 2. セキュリティ機能
- **機密情報検出**: コミット前の自動スキャン
- **環境変数分離**: 開発・本番環境の安全な分離
- **Git履歴保護**: 機密情報の履歴への混入防止

### 3. カスタマイズ
- **通知先設定**: チャンネル、DM、メンション設定
- **メッセージ形式**: カスタムメッセージテンプレート
- **フィルタリング**: 通知条件の詳細設定

## ドキュメント

- [詳細セットアップガイド](docs/setup.md)
- [設定リファレンス](docs/configuration.md)
- [トラブルシューティング](docs/troubleshooting.md)
- [貢献ガイドライン](CONTRIBUTING.md)

## 貢献

プルリクエストを歓迎します！以下の手順で貢献してください：

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m '素晴らしい機能を追加'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## サポート

- バグ報告: [Issues](https://github.com/ttrip-ngs/claude-code-hooks/issues)
- 質問・議論: [Discussions](https://github.com/ttrip-ngs/claude-code-hooks/discussions)

---

Created by [ttrip-ngs](https://github.com/ttrip-ngs)
