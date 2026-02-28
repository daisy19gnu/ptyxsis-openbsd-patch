# OpenBSD-7.7の環境で最新のPtyxisをコンパイルして利用したいです。なんならパッケージも作りたいです。一緒に考えてもらえますか？このマシンはFedora43です。

claudeの利用はこのホスト、
作業はOpenBSD7.7にssh openbsd77してコンパイルを行って下さい。この環境はdoasではなくsudoを利用します。

OpenBSD7.8のアップデートに伴い、コアダンプするようになってしまいました。OpenBSD7.7の時の成功体験を生かして、迅速にビルドを行って下さい。

これらのソースを一旦Geminiが触っています。CLAUDEに戻しますので、一旦全部の構成など見直して下さい。

## 重要なルール

### 新しいバージョンのチェック

作業開始時には、必ず以下の手順を実施してください：

1. **Ptyxisの最新バージョンを確認**
   - https://gitlab.gnome.org/chergert/ptyxis/-/tags で最新のリリースタグを確認
   - 現在のバージョン（Makefileの`V =`行）と比較

2. **新しいバージョンが存在する場合**
   - Makefileの`V =`行を更新
   - `make clean=dist`で完全なクリーンビルドを実施
   - 新バージョンでビルドを試行
   - 既存のパッチが適用できるか確認
   - 必要に応じてパッチを更新

3. **バージョンアップ時の注意点**
   - distinfoファイルは`make makesum`で自動更新
   - ビルドエラーが発生した場合は、上流の変更を確認
   - パッチが不要になった場合は削除を検討
   - 新機能がOpenBSDで動作するか確認

### 現在のバージョン情報

- **最後に確認した日**: 2026-02-28
- **使用中のバージョン**: 49.3
- **最新の安定版**: 49.3（次: 50.rcが開発中）
- **状態**: 最新版を使用中

### 適用済みパッチの概要

| パッチ | 内容 |
|--------|------|
| patch-agent_meson_build | GLIBC互換レイヤーをLinux限定に（OpenBSDはlibc直接使用） |
| patch-src_ptyxis-tab_c | sys/wait.h追加 + zoom_font_scales配列の`1,2`→`1.2`タイポ修正 |
| patch-src_ptyxis-util_c | wordexp(3)をOpenBSDで無効化 + NULLポインタ参照修正 |

### OpenBSD 7.8での既知の問題と解決策

- **クラッシュ原因**: wordexp(3)未対応によるNULL参照 + zoom配列タイポ
- **修正**: 上記パッチ3つで解決済み
- **ビルド方法**: portsシステム（WANTLIB問題あり）よりdirect mesonビルド推奨
  ```sh
  meson setup build --prefix=/usr/local --buildtype=debugoptimized -Ddevelopment=false
  ninja -C build
  sudo ninja -C build install
  ```
