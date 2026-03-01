# スクリプトリファレンス

このドキュメントでは、リポジトリに含まれるシェルスクリプトの使い方と設計を説明します。

## check-version.sh

現在 Makefile に記録されているバージョンと、上流のタグページを表示します。

```sh
./check-version.sh
```

出力例:

```
Current version : 49.3
Makefile updated: 2026-02-28 20:55:00
Upstream tags   : https://gitlab.gnome.org/chergert/ptyxis/-/tags
```

スクリプトはカレントディレクトリに依存しません。どこからでも実行できます。

---

## build-ptyxis.sh

Fedora ホストから OpenBSD へ SSH 経由でビルドを行います。
meson を直接使用するため、ports システムの WANTLIB 問題を回避できます。

### 使い方

```sh
# 現在のバージョン（Makefile の V=）でビルド
./build-ptyxis.sh

# バージョンを更新してビルド（Makefile も更新される）
./build-ptyxis.sh 49.4

# 別のホストを使用
OPENBSD_HOST=my-openbsd ./build-ptyxis.sh
```

### 環境変数

| 変数 | デフォルト | 説明 |
|------|----------|------|
| `OPENBSD_HOST` | `openbsd77` | OpenBSD 機の SSH ホスト名 |
| `REMOTE_SRCDIR` | `ptyxis-src` | リモートの作業ディレクトリ名 ($HOME 相対) |

### 処理フロー

```
1. バージョン確認（引数があれば Makefile を更新）
2. SSH 接続確認
3. openbsd-port/patches/ をリモートに同期 (scp)
4. リモートで:
   a. git clone / git fetch (https://gitlab.gnome.org/chergert/ptyxis.git)
   b. git checkout <version>
   c. patch -p0 で全パッチを適用
   d. meson setup build
   e. ninja -C build
   f. sudo ninja -C build install
```

### 前提条件

- SSH 鍵認証が設定済みであること (`ssh-copy-id openbsd77`)
- OpenBSD 側に依存パッケージがインストール済みであること

```sh
# OpenBSD 側で事前に実行
sudo pkg_add git meson ninja gtk+4 libadwaita vte3-gtk4 json-glib gsettings-desktop-schemas
```

---

## upstream-patches/ 内のスクリプト

上流 (GNOME GitLab) へバグ報告・パッチ提出を行うスクリプトです。
詳細は `upstream-patches/HOWTO_SUBMIT.md` を参照してください。

| スクリプト | 役割 |
|-----------|------|
| `create-issues.sh` | GitLab API で Issue を作成 |
| `fork-and-prepare.sh` | リポジトリをフォークしてパッチブランチを作成 |
| `create-mr.sh` | Merge Request を作成 |

これらのスクリプトには POSIX sh 互換の `/bin/sh` を使用しています。
`curl` と `python3` が必要です。

### 認証情報の設定

```sh
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
# または
echo 'export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"' > ~/.env-ptyxis-upstream
chmod 600 ~/.env-ptyxis-upstream
```
