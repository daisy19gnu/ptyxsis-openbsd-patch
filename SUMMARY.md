# Ptyxis for OpenBSD - プロジェクト状況

## 現在の状態

| 項目 | 内容 |
|------|------|
| Ptyxis バージョン | 49.3 |
| 対象 OS | OpenBSD 7.8 amd64 |
| ビルド方式 | direct meson ビルド (推奨) |
| パッチリビジョン | r2 |
| ビルド検証日 | 2026-03-02 |

## 適用中のパッチ (6つ)

| パッチ | 対象ファイル | 内容 |
|--------|------------|------|
| patch-agent_meson_build | agent/meson.build | GLIBC 互換ビルドを Linux 限定に |
| patch-agent_ptyxis-agent_c | agent/ptyxis-agent.c | pledge(2) によるシステムコール制限 (cpath 含む) |
| patch-agent_ptyxis-process-impl_c | agent/ptyxis-process-impl.c | sysctl(3) でプロセス情報取得 (/proc 不要化) |
| patch-src_main_c | src/main.c | XDG_RUNTIME_DIR 自動設定 |
| patch-src_ptyxis-tab_c | src/ptyxis-tab.c | sys/wait.h 追加 + zoom 配列タイポ修正 |
| patch-src_ptyxis-util_c | src/ptyxis-util.c | wordexp(3) 無効化 + NULL 参照修正 |

### OpenBSD 7.8 で修正した問題

| 問題 | 原因 | 修正パッチ |
|------|------|-----------|
| ptyxis-agent SIGABRT クラッシュ | pledge に cpath 不足 → g_mkdir_with_parents() で違反 | patch-agent_ptyxis-agent_c |
| タブタイトル・CWD 追跡不能 | /proc 依存のプロセス情報取得 | patch-agent_ptyxis-process-impl_c |
| wordexp NULL 参照クラッシュ | OpenBSD に wordexp(3) なし → ret が NULL | patch-src_ptyxis-util_c |
| zoom 配列タイポ | `1,2` が2要素に分割 | patch-src_ptyxis-tab_c |

## パッチバージョニング

```
openbsd-port/patches/
  patch-*                  <- 最新版 (ビルドスクリプト・ports 互換)
  ptyxis-49.3-r1/          <- 旧リビジョン (5パッチ、cpath なし)
  ptyxis-49.3-r2/          <- 現行リビジョン (6パッチ、diff -u 生成)
  ptyxis-49.3-r{1,2}.tar.gz  <- アーカイブ
```

## 上流へのバグ報告

以下の 2 件は全プラットフォームに影響するバグとして報告準備済み。

| パッチ | 内容 | 状態 |
|--------|------|------|
| 0001-fix-zoom_font_scales-array-typo.patch | zoom_font_scales 配列のタイポ | 報告準備済み |
| 0002-fix-null-deref-in-ptyxis_path_expand.patch | NULL ポインタ参照 | 報告準備済み |

報告手順: `upstream-patches/HOWTO_SUBMIT.md` を参照。

## 動作確認済み機能

- [x] ビルド成功 (OpenBSD 7.8 amd64, 全6パッチ適用)
- [x] 起動
- [x] 複数タブの作成・切り替え
- [x] 基本的な端末操作

## 次のアクション

1. 上流への Issue / MR 提出 (`upstream-patches/HOWTO_SUBMIT.md`)
2. Ptyxis 新バージョンのリリース確認 (`./check-version.sh`)
3. OpenBSD ports メーリングリスト (ports@openbsd.org) への提出検討
