# Claude Code Hooks Scripts - ディレクトリ構成

## 概要
Claude Codeのhooks機能で使用するスクリプト類を管理するリポジトリです。

## ディレクトリ構成

```
claude-code-hooks-scripts/
├── hooks/                     # 各hook種別のスクリプト
│   ├── pre-tool-use/          # ツール実行前に呼び出されるスクリプト
│   ├── post-tool-use/         # ツール実行後に呼び出されるスクリプト
│   ├── notification/          # 通知時に呼び出されるスクリプト
│   ├── stop/                  # メインエージェント応答終了時に呼び出されるスクリプト
│   └── subagent-stop/         # サブエージェント応答終了時に呼び出されるスクリプト
├── lib/                       # 共通ライブラリ
│   ├── common/                # 共通関数・設定
│   └── utils/                 # ユーティリティ関数
├── config/                    # 設定ファイル
│   └── examples/              # 設定例
├── docs/                      # ドキュメント
├── memo/                      # 開発履歴
│   └── history/               # 開発履歴の詳細
└── README.md                  # プロジェクト説明
```

## 各ディレクトリの役割

### hooks/
各hook種別のスクリプトを配置します。

#### pre-tool-use/
- ツール実行前の権限チェック
- 危険なコマンドの検証
- 実行環境の準備

#### post-tool-use/
- 実行結果の検証
- 自動フォーマット
- ログ記録
- 通知処理

#### notification/
- カスタム通知処理
- アラート送信
- 外部システム連携

#### stop/
- メインエージェントセッション終了時の後処理
- 作業完了通知
- ログの整理
- 一時ファイルの削除

#### subagent-stop/
- サブエージェント（Task tool）終了時の後処理
- サブタスク完了通知
- サブエージェント実行結果の記録
- 制御機能（停止ブロック等）

### lib/
複数のhookで共通利用される機能を配置します。

### config/
hooks設定ファイルの雛形とサンプルを配置します。
実際の設定ファイルは `$HOME/.config/claude-code-hooks-scripts/config.json` に配置されます。

### docs/
各スクリプトの使用方法やAPIドキュメントを配置します。

### memo/
開発履歴を記録します。CLAUDE.mdの指示に従い、修正内容・変更点を記録します。