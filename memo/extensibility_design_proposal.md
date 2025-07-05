# Claude Code Hooks Scripts 拡張性設計提案

## 📋 現状分析結果

### ✅ 優秀な基盤
- **階層的ディレクトリ構成**: Hook種別による適切な分離
- **共通ライブラリ**: 汎用的な機能（ログ、環境情報取得、時間計算）
- **JSON設定管理**: 一元的な設定管理システム

### ❌ 制約事項
- **Slack特化**: 現在の実装がSlack通知に完全特化
- **単一処理**: 1つのHookで1つの処理のみ
- **拡張困難**: 新しい処理種別の追加に大幅な改修が必要

## 🏗️ 提案：プロセッサー機構による拡張設計

### 基本概念
複数の「プロセッサー」を並列実行できるHookシステムへの転換

### 新しい設定形式例
```json
{
  "hooks": {
    "notification": {
      "processors": [
        {
          "type": "slack",
          "enabled": true,
          "config": {
            "channel": "#alerts",
            "webhook_url": "https://hooks.slack.com/services/...",
            "icon_emoji": ":warning:"
          }
        },
        {
          "type": "email",
          "enabled": true,
          "config": {
            "to": ["admin@example.com", "dev@example.com"],
            "smtp_server": "smtp.gmail.com",
            "smtp_port": 587,
            "subject_prefix": "[Claude Code]"
          }
        },
        {
          "type": "file",
          "enabled": true,
          "config": {
            "path": "/var/log/claude-hooks.log",
            "format": "json",
            "rotation": "daily"
          }
        },
        {
          "type": "database",
          "enabled": false,
          "config": {
            "type": "mysql",
            "host": "localhost",
            "database": "claude_logs",
            "table": "hook_events"
          }
        }
      ]
    },
    "stop": {
      "processors": [
        {
          "type": "slack",
          "enabled": true,
          "config": {
            "channel": "UJM1V2AAH",
            "webhook_url": "https://hooks.slack.com/services/..."
          }
        },
        {
          "type": "git",
          "enabled": true,
          "config": {
            "auto_commit": true,
            "commit_message_template": "Claude Code session completed: {session_id}"
          }
        },
        {
          "type": "cleanup",
          "enabled": true,
          "config": {
            "temp_dirs": ["/tmp/claude-*"],
            "max_age_hours": 24
          }
        }
      ]
    }
  }
}
```

## 🔧 実装ロードマップ

### Phase 1: 基盤整備（1-2週間）
1. **汎用プロセッサー基盤作成**
   - `lib/common/processor_manager.sh`
   - `lib/common/config_manager.sh`

2. **プロセッサーインターフェース定義**
   - 標準入出力形式の定義
   - エラーハンドリング規約

3. **既存Slack実装のプロセッサー化**
   - `lib/processors/slack_processor.sh`

### Phase 2: 多様なプロセッサー実装（2-4週間）
1. **基本プロセッサー群**
   - `lib/processors/email_processor.sh`: メール送信
   - `lib/processors/file_processor.sh`: ファイル出力
   - `lib/processors/api_processor.sh`: REST API連携

2. **システム連携プロセッサー**
   - `lib/processors/database_processor.sh`: DB操作
   - `lib/processors/git_processor.sh`: Git操作
   - `lib/processors/cleanup_processor.sh`: 環境整理

3. **高度なプロセッサー**
   - `lib/processors/webhook_processor.sh`: 汎用Webhook
   - `lib/processors/script_processor.sh`: カスタムスクリプト実行

### Phase 3: 高度な機能（1-2ヶ月）
1. **条件分岐機能**
   - 環境変数やセッション情報に基づく実行制御
   - フィルタリング機能

2. **並列処理最適化**
   - 非同期実行
   - タイムアウト制御

3. **監視・運用機能**
   - メトリクス収集
   - 失敗時の再実行

## 📁 新しいディレクトリ構成

```
claude-code-hooks-scripts/
├── hooks/
│   ├── notification/
│   │   └── process_manager.sh          # プロセッサー管理（汎用）
│   ├── stop/
│   │   └── process_manager.sh          # プロセッサー管理（汎用）
│   └── subagent-stop/
│       └── process_manager.sh          # プロセッサー管理（汎用）
├── lib/
│   ├── common/
│   │   ├── processor_manager.sh        # プロセッサー実行基盤
│   │   ├── config_manager.sh           # 設定管理
│   │   └── utils.sh                    # 共通ユーティリティ
│   └── processors/                     # プロセッサー実装
│       ├── slack_processor.sh          # Slack通知
│       ├── email_processor.sh          # メール送信
│       ├── file_processor.sh           # ファイル出力
│       ├── database_processor.sh       # DB操作
│       ├── api_processor.sh            # API連携
│       ├── git_processor.sh            # Git操作
│       ├── cleanup_processor.sh        # 環境整理
│       └── script_processor.sh         # カスタムスクリプト
└── config/
    └── examples/
        ├── basic-config.json           # 基本設定
        ├── advanced-config.json       # 高度な設定
        └── enterprise-config.json     # エンタープライズ設定
```

## 🔄 移行戦略

### 後方互換性の維持
1. **既存設定の自動変換**
   - 現在の`slack_notifications`形式を新形式に自動変換
   - 設定移行ツールの提供

2. **段階的移行**
   - 既存Hookの動作を保証しながら新機能を追加
   - デュアル設定サポート（旧形式と新形式の並行動作）

### 実装例：通知プロセッサー統合
```bash
# 新しいHookスクリプト例
#!/bin/bash
source "$LIB_DIR/common/processor_manager.sh"

# 複数プロセッサーを並列実行
execute_processors "notification" "$message" "$session_info"
```

## 💡 想定される利用例

### 開発環境
- Slack通知 + ファイルログ + Git自動コミット

### ステージング環境  
- Slack通知 + メール通知 + API連携（チケットシステム）

### 本番環境
- メール通知 + データベース記録 + 監視システム連携 + 自動クリーンアップ

## 🎯 期待される効果

1. **柔軟性**: 多様な処理を組み合わせ可能
2. **保守性**: プロセッサー単位での独立した保守
3. **テスト性**: プロセッサー単体でのテスト実行
4. **拡張性**: 新しいプロセッサーの簡単な追加
5. **再利用性**: プロセッサーの異なるHook間での共有

この設計により、Claude Code Hooksは「通知システム」から「包括的なHook実行プラットフォーム」へと進化します。