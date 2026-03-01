# Ptyxis for OpenBSD - プロジェクト状況

## 現在の状態

| 項目 | 内容 |
|------|------|
| Ptyxis バージョン | 49.3 |
| 対象 OS | OpenBSD 7.8 amd64 |
| ビルド方式 | direct meson ビルド (推奨) |
| 動作確認 | 2026-02-28 |

## 適用中のパッチ

| パッチ | 対象ファイル | 内容 |
|--------|------------|------|
| patch-agent_meson_build | agent/meson.build | GLIBC 互換ビルドを Linux 限定に |
| patch-agent_ptyxis-agent_c | agent/ptyxis-agent.c | pledge(2) によるシステムコール制限 |
| patch-src_main_c | src/main.c | XDG_RUNTIME_DIR 自動設定 |
| patch-src_ptyxis-tab_c | src/ptyxis-tab.c | sys/wait.h 追加 + zoom 配列タイポ修正 |
| patch-src_ptyxis-util_c | src/ptyxis-util.c | wordexp(3) 無効化 + NULL 参照修正 |

## 上流へのバグ報告

以下の 2 件は全プラットフォームに影響するバグとして上流に報告済み（または報告予定）。

| パッチ | 内容 | 状態 |
|--------|------|------|
| 0001-fix-zoom_font_scales-array-typo.patch | zoom_font_scales 配列のタイポ | 報告準備済み |
| 0002-fix-null-deref-in-ptyxis_path_expand.patch | NULL ポインタ参照 | 報告準備済み |

報告手順: `upstream-patches/HOWTO_SUBMIT.md` を参照。

## 動作確認済み機能

- ビルド成功 (OpenBSD 7.8 amd64)
- 起動
- 複数タブの作成・切り替え
- 基本的な端末操作

## リポジトリ構成

```
OpenBSD-Ptyxis/
├── openbsd-port/
│   ├── Makefile              # port 定義 (V=49.3)
│   ├── distinfo              # SHA256 チェックサム
│   ├── README.OpenBSD        # ports インストール向け説明
│   ├── patches/              # 5 つの OpenBSD 向けパッチ
│   └── pkg/
│       ├── DESCR
│       └── PLIST
├── upstream-patches/         # 上流報告用パッチと手順
├── build-ptyxis.sh           # SSH 経由自動ビルドスクリプト
├── check-version.sh          # バージョン確認スクリプト
├── BUILD_INSTRUCTIONS.md     # 詳細ビルド手順
└── README.md                 # プロジェクト概要
```

## 次のアクション

1. 上流への Issue / MR 提出 (`upstream-patches/HOWTO_SUBMIT.md`)
2. Ptyxis 新バージョンのリリース確認 (`./check-version.sh`)
3. OpenBSD ports メーリングリスト (ports@openbsd.org) への提出検討
