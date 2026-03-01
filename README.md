# Ptyxis for OpenBSD

OpenBSD 向けの [Ptyxis](https://gitlab.gnome.org/chergert/ptyxis) port です。
Ptyxis は GTK4/libadwaita ベースの GNOME ターミナルエミュレータです。

## 現在のバージョン

| 項目 | バージョン |
|------|-----------|
| Ptyxis | **49.3** |
| OpenBSD | 7.8 amd64 |
| ビルド確認日 | 2026-02-28 |

## 動作確認済み依存ライブラリ

| パッケージ | バージョン | 状態 |
|-----------|-----------|------|
| GTK4 | 4.20.2 | OK |
| libadwaita | 1.8.0 | OK |
| VTE (GTK4) | 0.80.4 | OK |
| JSON-GLib | 1.10.8 | OK |
| GLib | 2.84.4 | OK |

## リポジトリ構成

```
OpenBSD-Ptyxis/
├── openbsd-port/              # OpenBSD port ファイル群
│   ├── Makefile              # ビルド定義 (V=49.3)
│   ├── distinfo              # チェックサム (SHA256)
│   ├── README.OpenBSD        # OpenBSD 固有のビルド手順
│   ├── patches/              # OpenBSD 用パッチ (5つ)
│   │   ├── patch-agent_meson_build      # Linux専用ビルド制限
│   │   ├── patch-agent_ptyxis-agent_c   # pledge(2) によるセキュリティ強化
│   │   ├── patch-src_main_c             # XDG_RUNTIME_DIR 自動設定
│   │   ├── patch-src_ptyxis-tab_c       # sys/wait.h + zoom配列タイポ修正
│   │   └── patch-src_ptyxis-util_c      # wordexp(3)無効化 + NULLポインタ修正
│   └── pkg/                  # パッケージメタデータ
│       ├── DESCR             # パッケージ説明文
│       └── PLIST             # インストールファイルリスト
├── upstream-patches/          # 上流へのバグ報告用パッチ
│   ├── 0001-fix-zoom_font_scales-array-typo.patch
│   ├── 0002-fix-null-deref-in-ptyxis_path_expand.patch
│   ├── HOWTO_SUBMIT.md       # 上流へのパッチ提出手順
│   ├── create-issues.sh      # GitLab issue 作成スクリプト
│   ├── create-mr.sh          # GitLab MR 作成スクリプト
│   └── fork-and-prepare.sh   # フォーク準備スクリプト
├── build-ptyxis.sh            # 自動ビルドスクリプト
├── BUILD_INSTRUCTIONS.md      # 詳細なビルド手順
└── SUMMARY.md                 # 作業サマリー
```

## ビルド方法

### direct meson ビルド（推奨）

ports システムの WANTLIB 問題を回避するため、直接 meson ビルドを使用します。

```sh
# OpenBSD マシンにて
git clone https://gitlab.gnome.org/chergert/ptyxis.git
cd ptyxis
git checkout 49.3

# パッチ適用
patch -p1 < /path/to/openbsd-port/patches/patch-agent_meson_build
patch -p1 < /path/to/openbsd-port/patches/patch-agent_ptyxis-agent_c
patch -p1 < /path/to/openbsd-port/patches/patch-src_main_c
patch -p1 < /path/to/openbsd-port/patches/patch-src_ptyxis-tab_c
patch -p1 < /path/to/openbsd-port/patches/patch-src_ptyxis-util_c

# ビルド
meson setup build --prefix=/usr/local --buildtype=debugoptimized -Ddevelopment=false
ninja -C build
sudo ninja -C build install
```

### 実行

```sh
ptyxis
```

`XDG_RUNTIME_DIR` は `patch-src_main_c` により自動的に `/tmp/runtime-UID` に設定されます。

## OpenBSD 向けパッチの概要

### patch-agent_meson_build

GLIBC 互換レイヤーを Linux 専用に制限します。

```diff
-if target_machine.cpu_family() == 'x86_64'
+if target_machine.cpu_family() == 'x86_64' and target_machine.system() == 'linux'
```

OpenBSD は独自の libc を持つため、Linux 向けの GLIBC 互換シンボルは不要です。
このパッチなしでは agent のビルドが失敗します。

### patch-agent_ptyxis-agent_c

`pledge(2)` を使用して ptyxis-agent の権限を最小化します。

起動後に必要なシステムコールのみに制限します：

| pledge 権限 | 用途 |
|------------|------|
| `stdio` | 基本 I/O、wait4、kqueue、pipe |
| `rpath` | シェルバイナリ、/etc/passwd の読み取り |
| `wpath` | PTY 設定のための書き込み |
| `tty` | posix_openpt、grantpt、unlockpt |
| `proc` | fork、setpgid、kill |
| `exec` | ユーザーシェルの起動 |
| `unix` | D-Bus socketpair 通信 |
| `sendfd`/`recvfd` | D-Bus 経由の fd 受け渡し |
| `getpw` | ログインシェル解決 |

pledge 失敗時はサイレント継続ではなくエラー終了します（OpenBSD のセキュリティベストプラクティス準拠）。

### patch-src_main_c

OpenBSD では systemd が存在しないため `XDG_RUNTIME_DIR` が設定されません。
GTK4 と D-Bus はソケットファイルやキャッシュのためにこのディレクトリを必要とします。

未設定の場合、`/tmp/runtime-UID`（mode 0700）を自動作成して環境変数に設定します。

### patch-src_ptyxis-tab_c

2つの修正を含みます。

**sys/wait.h インクルード追加**

`WIFEXITED`、`WIFSIGNALED` 等のマクロが OpenBSD では `sys/wait.h` からのみ提供されます。
欠如するとリリースビルドで未定義動作が発生し、SIGTRAP クラッシュを引き起こします。

**zoom_font_scales 配列のタイポ修正（上流バグ）**

```c
// Before (bug): 17要素の配列になってしまう
1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1,2,
// After (fix)
1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2,
```

C の配列初期化子では `,` が要素区切りとなるため、`1,2` は2つの要素（1.0 と 2.0）に分割されます。
このバグは 49.2 と 49.3 の両方に存在します（上流へのバグ報告済み）。

### patch-src_ptyxis-util_c

2つの修正を含みます。

**wordexp(3) の無効化**

OpenBSD は `wordexp(3)` を提供しません。`~` と `$HOME` は別途処理済みのため、
OpenBSD では `g_strdup(path)` によるシンプルなフォールバックを使用します。

**NULL ポインタ参照の修正（上流バグ）**

```c
// Before (bug): ret が NULL の場合クラッシュ
if (!g_path_is_absolute(ret))
// After (fix)
if (ret != NULL && !g_path_is_absolute(ret))
```

これはリリースビルドで SIGTRAP クラッシュを引き起こしていた主要な原因です。

## 動作確認状況

- [x] ビルド成功（OpenBSD 7.8 amd64）
- [x] 起動確認
- [x] 複数タブの作成（4タブ以上）
- [x] タブ間の切り替え
- [x] 基本的な端末操作

## 利用できない機能（Linux 専用）

| 機能 | 理由 |
|------|------|
| Podman/Toolbox/Distrobox 統合 | Linux コンテナランタイム依存 |
| libportal 機能 | Flatpak ポータル依存 |
| systemd スコープ | systemd 依存 |

## 参考リンク

- [Ptyxis 上流リポジトリ](https://gitlab.gnome.org/chergert/ptyxis)
- [OpenBSD Ports ガイド](https://www.openbsd.org/faq/ports/)
