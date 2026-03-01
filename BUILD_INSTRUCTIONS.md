# Ptyxis for OpenBSD - ビルド手順

OpenBSD 7.8 amd64 上で Ptyxis 49.3 をビルドする手順を説明します。

## 推奨ビルド方法: direct meson ビルド

ports ツリーは WANTLIB のバージョン管理が煩雑なため、直接 meson でビルドします。

### 前提条件

以下のパッケージが必要です。

```sh
sudo pkg_add git meson ninja
sudo pkg_add gtk+4 libadwaita vte3-gtk4 json-glib gsettings-desktop-schemas
```

| パッケージ | 最低バージョン | OpenBSD 7.8 |
|-----------|--------------|-------------|
| GLib | 2.80 | 2.84.4 |
| GTK4 | 4.14 | 4.20.2 |
| libadwaita | 1.8 | 1.8.0 |
| VTE (GTK4) | 0.79 | 0.80.4 |
| JSON-GLib | 1.6 | 1.10.8 |
| meson | 1.0.0 | 1.9.1 |

### ソースの取得とパッチ適用

```sh
git clone https://gitlab.gnome.org/chergert/ptyxis.git
cd ptyxis
git checkout 49.3

# OpenBSD 用パッチを適用（このリポジトリの openbsd-port/patches/ から）
patch -p0 < /path/to/openbsd-port/patches/patch-agent_meson_build
patch -p0 < /path/to/openbsd-port/patches/patch-agent_ptyxis-agent_c
patch -p0 < /path/to/openbsd-port/patches/patch-src_main_c
patch -p0 < /path/to/openbsd-port/patches/patch-src_ptyxis-tab_c
patch -p0 < /path/to/openbsd-port/patches/patch-src_ptyxis-util_c
```

### ビルドとインストール

```sh
meson setup build \
    --prefix=/usr/local \
    --buildtype=debugoptimized \
    -Ddevelopment=false

ninja -C build
sudo ninja -C build install
```

### 実行

```sh
ptyxis
```

`XDG_RUNTIME_DIR` は patch-src_main_c により `/tmp/runtime-$(id -u)` に自動設定されます。
設定スキーマは meson install が自動でコンパイルします。

---

## ports ツリー経由のビルド

参照用として手順を残します。WANTLIB の問題が発生した場合は meson 直接ビルドを使用してください。

### port ファイルの配置

```sh
sudo mkdir -p /usr/ports/x11/ptyxis
sudo cp -r /path/to/openbsd-port/* /usr/ports/x11/ptyxis/
```

### ビルド

```sh
cd /usr/ports/x11/ptyxis
make makesum       # distinfo を更新
make patch         # パッチ適用を確認
make build
sudo make install
```

### パッケージ作成

```sh
make package
# 生成先: /usr/ports/packages/$(uname -m)/all/ptyxis-49.3.tgz
```

---

## 自動ビルドスクリプト

Fedora ホストから OpenBSD へ SSH 経由でビルドする場合は `build-ptyxis.sh` を使用します。

```sh
# デフォルトホスト (openbsd77) でビルド
./build-ptyxis.sh

# 別ホストを指定
OPENBSD_HOST=myhost ./build-ptyxis.sh

# バージョンを上げてビルド
./build-ptyxis.sh 49.4
```

スクリプトは SSH 鍵認証が設定済みであることを前提とします。
ホスト名の変更は環境変数 `OPENBSD_HOST` で行います（スクリプト内の書き換えは不要）。

---

## トラブルシューティング

### パッチが当たらない

新バージョンで上流コードが変更された場合は、パッチを更新します。

```sh
cd ptyxis
git diff HEAD > /tmp/my-changes.patch
```

差分を確認し、`openbsd-port/patches/` 内の該当パッチを修正してください。

### ビルドエラー

```sh
ninja -C build 2>&1 | tee /tmp/build.log
```

ログを確認して原因を特定します。

### インストール後に起動しない

```sh
# GSettings スキーマを手動でコンパイル
sudo glib-compile-schemas /usr/local/share/glib-2.0/schemas/

# デスクトップデータベースを更新
sudo update-desktop-database /usr/local/share/applications/
```

### WANTLIB エラー (ports 使用時)

```
Error: Libraries in packing-lists ... don't match
```

Makefile に `WANTLIB` 行が含まれている場合に発生します。
現在の Makefile には `WANTLIB` は含まれていませんが、
バージョンアップ後に再発した場合は meson 直接ビルドに切り替えてください。

---

## OpenBSD 固有の制限事項

| 機能 | 状態 | 理由 |
|------|------|------|
| Podman/Toolbox/Distrobox 統合 | 無効 | Linux コンテナランタイム依存 |
| libportal 機能 | 無効 | Flatpak ポータル依存 |
| systemd スコープ | 無効 | systemd 依存 |

---

## 参考リンク

- [Ptyxis 上流リポジトリ](https://gitlab.gnome.org/chergert/ptyxis)
- [Ptyxis リリースタグ](https://gitlab.gnome.org/chergert/ptyxis/-/tags)
- [OpenBSD Ports ガイド](https://www.openbsd.org/faq/ports/)
- [openports.pl](https://openports.pl/)
