# Claude Code Hooks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/ttrip-ngs/claude-code-hooks/pulls)

Claude Code（Anthropic社のCLIツール）のフック機能を活用した便利なスクリプト集です。作業効率化とチーム連携を支援する様々なフックスクリプトを提供します。

## 概要

Claude Code Hooksは、Claude Codeのイベントフック機能を利用して、開発ワークフローを自動化・拡張するためのスクリプト集です。現在は以下のスクリプトを提供しています：

- **Slack通知スクリプト**: Claude Codeの作業状況をSlackに自動通知

今後、さらに多くの便利なフックスクリプトを追加予定です。

## 必要条件

- Bash 4.0以上
- Git
- jq（JSON処理用）
- curl（HTTP通信用）
- Claude Code（インストール済み）

## インストール

```bash
# リポジトリをクローン
git clone https://github.com/ttrip-ngs/claude-code-hooks.git
cd claude-code-hooks

# 環境設定ファイルを作成（Slack通知を使用する場合）
cp .env.example .env
# .envファイルを編集して必要な設定を行う
```

## 利用可能なフックスクリプト

### 1. Slack通知フック

Claude Codeの作業イベントをSlackに通知するスクリプトです。

#### セットアップ

```bash
# 環境変数を設定
source .env

# Claude Code設定ファイルにフックを追加
mkdir -p ~/.claude
cat >> ~/.claude/settings.toml << 'EOF'
[hooks]
stop = "/path/to/claude-code-hooks/hooks/stop/slack.sh"
notification = "/path/to/claude-code-hooks/hooks/notification/slack.sh"
subagent-stop = "/path/to/claude-code-hooks/hooks/subagent-stop/slack.sh"
EOF

# テスト通知
./hooks/notification/slack.sh info "セットアップ完了！"
```

詳細は [Slack通知セットアップガイド](docs/slack-notification-setup.md) を参照してください。

## プロジェクト構造

```
claude-code-hooks/
├── hooks/              # フックスクリプト
│   ├── notification/   # 通知フック
│   ├── stop/          # 作業完了フック
│   └── subagent-stop/ # サブエージェント完了フック
├── scripts/           # ユーティリティスクリプト
├── config/            # 設定ファイル
├── docs/              # ドキュメント
└── examples/          # サンプルコード
```

## 新しいフックスクリプトの追加

このリポジトリに新しいフックスクリプトを追加する際は、以下の構造に従ってください：

1. `hooks/[イベント名]/[スクリプト名].sh` にスクリプトを配置
2. 必要な設定ファイルは `config/` に配置
3. ドキュメントを `docs/` に追加
4. サンプルコードを `examples/` に追加

## Claude Codeのフックイベント

Claude Codeは以下のイベントでフックをサポートしています：

- `notification`: 一般的な通知イベント
- `stop`: Claude Codeの作業終了時
- `subagent-stop`: サブエージェントの作業終了時

各イベントの詳細は [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks) を参照してください。

## 貢献

新しいフックスクリプトの追加やバグ修正のプルリクエストを歓迎します！

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/new-hook-script`)
3. 変更をコミット (`git commit -m '新しいフックスクリプトを追加'`)
4. ブランチにプッシュ (`git push origin feature/new-hook-script`)
5. プルリクエストを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## サポート

- バグ報告: [Issues](https://github.com/ttrip-ngs/claude-code-hooks/issues)
- 質問・議論: [Discussions](https://github.com/ttrip-ngs/claude-code-hooks/discussions)

---

Created by [ttrip-ngs](https://github.com/ttrip-ngs)
