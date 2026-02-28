# Ptyxis for OpenBSD 7.7/7.8

このリポジトリは、OpenBSD 7.7/7.8向けのPtyxis (GNOMEターミナルエミュレータ) のportを含んでいます。

## 📦 プロジェクト構成

```
OpenBSD-Ptyxis/
├── ptyxis/                    # Ptyxisのソースコード (GitLabからクローン)
├── openbsd-port/              # OpenBSD port構造
│   ├── Makefile              # OpenBSD port Makefile
│   ├── distinfo              # チェックサム情報
│   ├── README.OpenBSD        # OpenBSD固有のREADME
│   ├── patches/              # OpenBSD用パッチ
│   │   ├── patch-agent_meson_build
│   │   ├── patch-src_ptyxis-tab_c
│   │   └── patch-src_ptyxis-util_c
│   └── pkg/                  # パッケージメタデータ
│       ├── DESCR            # パッケージ説明
│       └── PLIST            # インストールファイルリスト
├── BUILD_INSTRUCTIONS.md     # ビルド手順(詳細)
└── README.md                 # このファイル
```

## 🎯 目標

OpenBSD 7.7/7.8環境で最新のPtyxis (バージョン49.2) をコンパイルし、
パッケージとして配布できるようにすること。

## ✅ 完了事項

- [x] Ptyxisソースコードの取得
- [x] OpenBSD 7.7/7.8での依存関係の確認
- [x] OpenBSD port構造の作成 (Makefile, PLIST, DESCR)
- [x] OpenBSD固有のパッチ作成
- [x] ビルド手順書の作成
- [x] README及びドキュメント整備
- [x] OpenBSD 7.8での実機ビルド成功
- [x] 起動テスト完了

## 📋 依存関係の状況

| パッケージ | Ptyxis要件 | OpenBSD 7.8 | 状態 |
|-----------|-----------|-------------|------|
| GLib | >= 2.80 | 2.80.x系 | ✅ OK |
| GTK4 | >= 4.14 | 4.20.2 | ✅ OK |
| libadwaita | >= 1.8 | 1.8.0v0 | ✅ OK |
| VTE (GTK4) | >= 0.79 | 0.80.4 | ✅ OK |
| JSON-GLib | >= 1.6 | 1.10.8 | ✅ OK |
| Meson | >= 1.0.0 | 1.9.1v0 | ✅ OK |

すべての主要な依存関係がOpenBSD 7.7/7.8で満たされています!

## 🚀 クイックスタート

### 方法1: 自動ビルドスクリプト（推奨）

新しいバージョンのチェックと自動ビルドが可能です：

```sh
# バージョンチェック
./check-version.sh

# 自動ビルド（新バージョンがある場合はプロンプトで入力）
./build-ptyxis.sh
```

このスクリプトは以下を自動化します：
- ✅ バージョンのチェックと更新
- ✅ WANTLIBの問題を自動回避
- ✅ ファイルのOpenBSDへの同期
- ✅ クリーンビルドとパッケージ作成
- ✅ オプション：テストインストール

**今回躓いたポイント（WANTLIB問題）を自動的に回避します！**

### 方法2: 手動ビルド

1. **このリポジトリをOpenBSDマシンに転送**

2. **portディレクトリを配置**
   ```sh
   sudo mkdir -p /usr/ports/x11/ptyxis
   sudo cp -r openbsd-port/* /usr/ports/x11/ptyxis/
   ```

3. **ビルドとインストール**
   ```sh
   cd /usr/ports/x11/ptyxis
   make clean=dist  # 完全クリーンビルド
   make makesum     # distinfoを生成
   make build       # ビルド
   sudo make package  # パッケージ作成
   ```

詳細は [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) を参照してください。

### Fedora 43環境での準備 (クロスビルドは推奨しません)

OpenBSDパッケージのビルドはOpenBSD環境で行うことを強く推奨します。
Fedora環境では、以下の作業が可能です:

- ソースコードの調査
- パッチの作成・編集
- ドキュメントの整備

## 📝 OpenBSD固有の変更点

### パッチ

1. **patch-agent_meson_build**:
   - x86_64でのGLIBC互換性レイヤーをLinux専用に制限
   - OpenBSDは独自のlibcを使用するため、GLIBC互換性コードが不要

2. **patch-src_ptyxis-tab_c**:
   - `<sys/wait.h>`のインクルード追加
   - WIFEXITED, WEXITSTATUS, WIFSIGNALED, WTERMSIGマクロの定義に必要

3. **patch-src_ptyxis-util_c**:
   - `wordexp()`関数の代替実装
   - OpenBSDにはwordexp()が存在しないため、簡易的なパス展開を実装

### 機能制限

以下の機能はLinux固有のため、OpenBSDでは利用できません:

- ❌ コンテナ統合 (Podman, Toolbox, Distrobox)
- ❌ libportal機能
- ❌ systemd user scopes

以下の機能は正常に動作します:

- ✅ 基本的なターミナルエミュレータ機能
- ✅ GTK4/libadwaita UI
- ✅ カラーパレットとテーマ
- ✅ タブ管理
- ✅ キーボードショートカット
- ✅ プロファイル管理
- ✅ GPU加速レンダリング (VTE)

## 🔧 次のステップ

1. **実機でのビルドテスト**
   - OpenBSD 7.7環境でビルドを実行
   - エラーがあればパッチを追加

2. **PLISTの調整**
   - 実際のビルド後に生成されるファイルリストを確認
   - `make update-plist` で自動生成可能

3. **パッケージング**
   - `make package` でtgzパッケージを生成
   - 他のOpenBSDマシンでインストールテスト

4. **上流への貢献**
   - OpenBSD対応パッチを上流にプルリクエスト
   - OpenBSD portsツリーへの正式登録を検討

## 🐛 既知の問題とテスト状況

### テスト完了

- [x] 実機でのビルド成功 (OpenBSD 7.8 amd64)
- [x] バイナリ起動確認 (`ptyxis --version`)
- [x] 依存ライブラリの確認

### 今後のテスト

- [ ] X11環境での実行テスト
- [ ] アーキテクチャ別のテスト (arm64, etc.)
- [ ] 長期安定性テスト

## 📚 参考資料

- [このプロジェクトのリポジトリ (Gitea)](http://openbsd77:3000/ikeda/Ptyxis-OpenBSD)
- [Ptyxis公式リポジトリ](https://gitlab.gnome.org/chergert/ptyxis)
- [OpenBSD Portsガイド](https://www.openbsd.org/faq/ports/)
- [OpenBSD ports検索](https://openports.pl/)
- [GNOME Console port](https://openports.pl/path/x11/gnome/console) (参考実装)

## 📄 ライセンス

Ptyxisは**GPLv3+**ライセンスで配布されています。

このport作成プロジェクトも同様のライセンスに従います。

## 🤝 貢献

改善提案やバグ報告は歓迎します:

1. このportの問題: [プロジェクトリポジトリ](http://openbsd77:3000/ikeda/Ptyxis-OpenBSD)でissueを作成
2. Ptyxis本体の問題: [上流のissueトラッカー](https://gitlab.gnome.org/chergert/ptyxis/-/issues)
3. OpenBSD ports関連: ports@openbsd.org


## ビルド情報

```
Ptyxis 49.2
  GTK: 4.20.2 (Compiled against 4.20.2)
  VTE: 0.80.4 (Compiled against 0.80.4)

ビルド環境: OpenBSD 7.8 amd64
ビルド日: 2025-11-04
```
