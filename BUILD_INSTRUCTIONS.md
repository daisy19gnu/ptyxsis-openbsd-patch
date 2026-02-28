# Ptyxis for OpenBSD 7.7/7.8 - Build Instructions

このドキュメントでは、OpenBSD 7.7/7.8環境でPtyxis 49.2をビルドしてパッケージ化する手順を説明します。

## 重要: ビルド前の確認事項

### 最新バージョンのチェック

ビルドを開始する前に、必ず最新バージョンを確認してください：

```sh
# 最新バージョンをWebで確認
# https://gitlab.gnome.org/chergert/ptyxis/-/tags

# 現在のバージョンを確認
cat openbsd-port/Makefile | grep "^V ="
```

**新しいバージョンがある場合の手順**：

1. `openbsd-port/Makefile`の`V =`行を更新
2. OpenBSD上で以下を実行：
   ```sh
   cd /usr/ports/x11/ptyxis
   make clean=dist        # 完全クリーンアップ
   make makesum           # 新しいチェックサムを生成
   make patch             # パッチが正常に適用されるか確認
   make build             # ビルド試行
   ```
3. エラーが出た場合は、パッチの更新が必要な可能性があります

**現在のバージョン情報**:
- 使用中: 49.2 (2025-11-07時点で最新)
- 前回チェック: 2025-11-07

## 前提条件

### 1. OpenBSD 7.7/7.8システムの準備

OpenBSD 7.7または7.8がインストールされたシステムが必要です。

### 2. portsツリーのインストール

```sh
# portsツリーを取得(まだの場合)
cd /tmp
ftp https://cdn.openbsd.org/pub/OpenBSD/$(uname -r)/{ports.tar.gz,SHA256.sig}
signify -Cp /etc/signify/openbsd-$(uname -r | cut -c 1,3)-base.pub -x SHA256.sig ports.tar.gz

# portsツリーを展開
cd /usr
tar xzf /tmp/ports.tar.gz
```

### 3. 必要な依存パッケージの確認

以下のパッケージがOpenBSD 7.7/7.8で利用可能です:

- `meson` >= 1.0.0 (7.8: 1.9.1v0)
- `glib2` >= 2.80 (7.8: 2.80.x)
- `gtk+4` >= 4.14 (7.8: 4.20.2)
- `libadwaita` >= 1.8 (7.8: 1.8.0v0)
- `vte3-gtk4` >= 0.79 (7.8: 0.80.4) - **注: OpenBSD 7.8ではdevel/vte3に移動**
- `json-glib` >= 1.6 (7.8: 1.10.8)
- `gsettings-desktop-schemas` (7.8: 48.0)

これらは依存関係として自動的にインストールされます。

### 4. OpenBSD 7.8固有の注意事項

OpenBSD 7.8では以下の変更があります:

- `vte3-gtk4`のパスが`x11/vte3,-gtk4`から`devel/vte3,-gtk4`に変更
- 一部のライブラリがマイナーバージョンアップ

## ビルド手順

### 方法1: OpenBSD portsツリーでビルド

1. **portディレクトリの配置**

```sh
# portディレクトリを適切な場所に配置
sudo mkdir -p /usr/ports/x11/ptyxis
sudo cp -r /path/to/openbsd-port/* /usr/ports/x11/ptyxis/
```

2. **distファイルの取得とチェックサムの更新**

```sh
cd /usr/ports/x11/ptyxis
make makesum  # distinfoファイルを自動生成
```

3. **ビルド**

```sh
make
```

4. **インストール**

```sh
doas make install
```

5. **パッケージ作成**

```sh
make package
```

生成されたパッケージは `/usr/ports/packages/$(uname -m)/all/` に配置されます。

### 方法2: 直接ソースからビルド (開発用)

1. **ソースコードの取得**

```sh
git clone https://gitlab.gnome.org/chergert/ptyxis.git
cd ptyxis
```

2. **依存パッケージのインストール**

```sh
doas pkg_add meson gtk+4 libadwaita vte3-gtk4 json-glib gsettings-desktop-schemas
```

3. **ビルド設定**

```sh
meson setup _build --prefix=/usr/local --buildtype=release
```

4. **コンパイル**

```sh
meson compile -C _build
```

5. **インストール**

```sh
doas meson install -C _build
```

## OpenBSD固有の注意事項

### コンテナ機能について

Ptyxisは本来、Podman、Toolbox、Distroboxなどのコンテナとの統合機能を持っていますが、
これらはLinux固有の機能です。OpenBSD版では:

- コンテナ検出機能は動作しません
- 基本的なターミナルエミュレータとして動作します
- すべてのGNOME統合機能(テーマ、ショートカット等)は利用可能です

### libportalについて

`libportal-gtk4`はLinux固有の依存関係で、OpenBSDビルドでは自動的に無効化されます。
これは一部のポータル機能に影響しますが、コア機能には影響しません。

### 適用されるパッチ

Ptyxis 49.2をOpenBSDでビルドするために、以下のパッチが適用されます:

1. **patch-agent_meson_build**: GLIBC互換性レイヤーの無効化
   - x86_64アーキテクチャでもGLIBC互換性コードをOpenBSDで無効化
   - OpenBSDは独自のlibcを使用

2. **patch-src_ptyxis-tab_c**: sys/wait.hのインクルード
   - WIFEXITED, WEXITSTATUS, WIFSIGNALED, WTERMSIGマクロに必要

3. **patch-src_ptyxis-util_c**: wordexp()の代替実装
   - OpenBSDにはPOSIX wordexp()が存在しないため、簡易的なパス展開を実装
   - ~（チルダ）と$HOME変数の展開をサポート

## トラブルシューティング

### ビルドエラーが発生した場合

1. **依存関係の確認**
   ```sh
   cd /usr/ports/x11/ptyxis
   make show=BUILD_DEPENDS RUN_DEPENDS LIB_DEPENDS
   ```

2. **ログの確認**
   ```sh
   make 2>&1 | tee build.log
   ```

3. **クリーンビルド**
   - `Makefile`やパッチの変更が反映されない場合は、通常の`make clean`では不十分なことがあります。
   - 特にビルドシステム(`meson.build`など)に関わるパッチを変更した場合は、以下の**完全なクリーンビルド**を実行してください。

   ```sh
   # 古いビルド設定を完全に削除
   make clean=dist

   # 再ビルド
   make
   ```

### パッケージが起動しない場合

1. **GSettings schemas のコンパイル確認**
   ```sh
   doas glib-compile-schemas /usr/local/share/glib-2.0/schemas/
   ```

2. **デスクトップデータベースの更新**
   ```sh
   doas update-desktop-database /usr/local/share/applications
   ```

3. **アイコンキャッシュの更新**
   ```sh
   doas gtk-update-icon-cache /usr/local/share/icons/hicolor
   ```

### OpenBSD 7.8でのビルドエラー

OpenBSD 7.8でビルドエラーが発生した場合:

1. **vte3パスの確認**
   - OpenBSD 7.8では`vte3`が`devel/vte3`に移動しています
   - Makefileで`LIB_DEPENDS`が`devel/vte3,-gtk4`になっているか確認

2. **完全なクリーンビルド**
   ```sh
   make clean=dist
   make
   ```

3. **権限の確認**
   - `/usr/ports/pobj`と`/usr/ports/distfiles`に書き込み権限があるか確認
   ```sh
   sudo chown -R $USER:wheel /usr/ports/pobj /usr/ports/distfiles
   ```

## 実行方法

インストール後、以下の方法で起動できます:

```sh
# コマンドラインから
ptyxis

# 新しいウィンドウを開く
ptyxis --new-window

# ヘルプを表示
ptyxis --help
```

GNOMEデスクトップ環境では、アプリケーションメニューから「Ptyxis」を選択できます。

## パッケージの配布

生成されたパッケージは以下の方法で他のOpenBSDシステムにインストールできます:

```sh
doas pkg_add /path/to/ptyxis-49.2.tgz
```

## 上流へのフィードバック

OpenBSD固有の問題が見つかった場合:

1. まずこのportの問題かどうか確認
2. 上流のissueトラッカーで報告: https://gitlab.gnome.org/chergert/ptyxis/-/issues
3. OpenBSD portsメーリングリストでも議論可能

## 参考リンク

- Ptyxis for OpenBSD プロジェクトリポジトリ: http://openbsd77:3000/ikeda/Ptyxis-OpenBSD
- Ptyxis公式リポジトリ: https://gitlab.gnome.org/chergert/ptyxis
- OpenBSD Portsガイド: https://www.openbsd.org/faq/ports/
- OpenBSD ports検索: https://openports.pl/

## ライセンス

Ptyxis は GPLv3+ ライセンスの下で配布されています。
詳細は `/usr/local/share/licenses/ptyxis/` を参照してください。
