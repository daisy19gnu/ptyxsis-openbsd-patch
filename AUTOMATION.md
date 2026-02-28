# Ptyxis for OpenBSD - 自動化ガイド

このドキュメントでは、Ptyxisのビルドプロセスを自動化するスクリプトについて説明します。

## 概要

今回のビルド作業で躓いたポイント（特にWANTLIBの問題）を自動的に回避し、
新しいバージョンのビルドを簡単にするためのスクリプトを提供しています。

## 提供されているスクリプト

### 1. check-version.sh

**目的**: Ptyxisの最新バージョンをチェック

**使い方**:
```bash
./check-version.sh
```

**機能**:
- 現在使用中のバージョンを表示
- GitLabのタグページのURLを表示
- 次のステップを提案

**出力例**:
```
[INFO] === Ptyxis バージョンチェック ===

[VERSION] 現在使用中のバージョン: 49.2
[INFO] Makefileの最終更新: 2025-11-07 03:47:00

[INFO] GitLabのタグページ: https://gitlab.gnome.org/chergert/ptyxis/-/tags
[WARN] ブラウザで上記URLを開き、最新の安定版タグを確認してください
```

### 2. build-ptyxis.sh

**目的**: Ptyxisの自動ビルドとパッケージング

**使い方**:
```bash
./build-ptyxis.sh
```

**機能**:
1. ✅ バージョンチェック（新バージョンがあればMakefile更新）
2. ✅ Makefileの検証（WANTLIBが含まれていないか確認）
3. ✅ ファイルのOpenBSDへの自動同期
4. ✅ クリーンビルドの実施
5. ✅ パッケージ作成
6. ✅ オプション：テストインストール

**実行フロー**:
```
1. バージョン確認
   ↓
2. Makefile検証（WANTLIB問題を自動回避）
   ↓
3. ファイル同期（Fedora → OpenBSD）
   ↓
4. OpenBSD上でビルド
   - make clean=dist
   - make fetch && make makesum
   - make patch
   - make build
   - sudo make package
   ↓
5. パッケージをFedoraにコピー
   ↓
6. オプション：テストインストール
```

**対話的な使用例**:
```bash
$ ./build-ptyxis.sh

[INFO] === Ptyxis for OpenBSD - 自動ビルドスクリプト ===

[INFO] 最新バージョンを確認中...
[WARN] 手動で https://gitlab.gnome.org/chergert/ptyxis/-/tags を確認してください
[INFO] 現在のバージョン: 49.2
新しいバージョンでビルドしますか？ (バージョン番号を入力、Enterでスキップ): 49.3
[INFO] バージョンを 49.3 に更新します
[INFO] Makefileを更新しました

[INFO] Makefileの検証中...
[INFO] OK: WANTLIBは自動検出に設定されています

[INFO] OpenBSDにファイルを同期中...
[INFO] ファイル同期完了

[INFO] OpenBSD上でビルドを開始...
[INFO] Step 1/5: クリーンアップ...
[INFO] Step 2/5: ソースのダウンロードとチェックサム更新...
[INFO] Step 3/5: パッチ適用...
[INFO] Step 4/5: コンパイル中（時間がかかります）...
[INFO] Step 5/5: パッケージ作成...
[INFO] ビルド完了！

[INFO] パッケージをFedoraにコピー中...
[INFO] 完了！パッケージ: /home/ikeda/OpenBSD-Ptyxis/ptyxis-49.3.tgz

[WARN] テストインストールを実行しますか？ [y/N]
y
[INFO] 既存のptyxisを削除中...
[INFO] 新しいパッケージをインストール中...
[INFO] バージョン確認...
Ptyxis 49.3
  GTK: 4.20.2 (Compiled against 4.20.2)
  VTE: 0.80.4 (Compiled against 0.80.4)
[INFO] テストインストール成功！

[INFO] === すべての処理が完了しました ===
```

## 今回躓いたポイントの自動化

### 問題1: WANTLIBのバージョン不一致

**症状**:
```
Error: Libraries in packing-lists in the ports tree
       and libraries from installed packages don't match
```

**原因**:
- OpenBSD 7.8でライブラリのマイナーバージョンが更新された
- Makefileに明示的な`WANTLIB`が含まれていた

**自動化による解決**:
```bash
# build-ptyxis.sh の verify_makefile() 関数で自動チェック
if grep -q "^WANTLIB" "$WORK_DIR/openbsd-port/Makefile"; then
    log_error "Makefileに WANTLIB が含まれています！"
    log_error "OpenBSD 7.8以降では、WANTLIBの自動検出を推奨します"
    # ユーザーに警告を表示
fi
```

現在のMakefileでは`WANTLIB`行を削除済みなので、この問題は発生しません。

### 問題2: ファイルの競合

**症状**:
```
Collision in ptyxis-49.2: the following files already exist
```

**原因**:
- 以前の手動インストールやテストビルドのファイルが残っていた

**自動化による解決**:
```bash
# build-ptyxis.sh の test_install() 関数
log_info "既存のptyxisを削除中..."
ssh "$OPENBSD_HOST" "sudo pkg_delete ptyxis || true"
ssh "$OPENBSD_HOST" "sudo rm -f /usr/local/bin/ptyxis /usr/local/libexec/ptyxis-agent"
```

### 問題3: 不完全なクリーンビルド

**症状**:
- `make clean`だけでは、ビルド設定が完全にクリーンアップされない
- パッチの変更が反映されない

**自動化による解決**:
```bash
# build-ptyxis.sh では常に完全クリーンビルド
ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && make clean=dist"
```

## スクリプトのカスタマイズ

### OpenBSDホスト名の変更

スクリプトの先頭でホスト名を設定しています：

```bash
# build-ptyxis.sh
OPENBSD_HOST="openbsd77"

# 別のホストを使う場合は変更
OPENBSD_HOST="my-openbsd-server"
```

### パスの変更

```bash
# build-ptyxis.sh
WORK_DIR="/home/ikeda/OpenBSD-Ptyxis"
REMOTE_PORT_DIR="/usr/ports/x11/ptyxis"

# 環境に合わせて変更
WORK_DIR="/home/yourname/ptyxis-work"
```

## トラブルシューティング

### スクリプトが実行できない

```bash
# 実行権限を付与
chmod +x check-version.sh
chmod +x build-ptyxis.sh
```

### SSHの接続に失敗する

```bash
# SSH接続をテスト
ssh openbsd77 "uname -a"

# SSHキーを設定済みか確認
ssh-copy-id openbsd77
```

### ビルドが途中で失敗する

```bash
# OpenBSD上で手動確認
ssh openbsd77
cd /usr/ports/x11/ptyxis
make build 2>&1 | tee /tmp/build.log

# ログを確認
less /tmp/build.log
```

## ベストプラクティス

### 定期的なバージョンチェック

月に1回程度、最新バージョンをチェックすることを推奨：

```bash
# crontabに追加する例（月初に通知）
0 9 1 * * cd /home/ikeda/OpenBSD-Ptyxis && ./check-version.sh | mail -s "Ptyxis Version Check" user@example.com
```

### バックアップ

ビルド前にバックアップを作成：

```bash
# パッケージのバックアップ
cp ptyxis-*.tgz backups/ptyxis-$(date +%Y%m%d).tgz

# Makefileのバックアップ（スクリプトが自動的に作成）
# openbsd-port/Makefile.bak
```

### テスト環境の利用

本番環境に導入する前に、テスト用のOpenBSDシステムで確認：

```bash
# テスト環境でのインストール
ssh openbsd-test "sudo pkg_add -Dunsigned /path/to/ptyxis-49.3.tgz"
ssh openbsd-test "ptyxis --version"
```

## 今後の改善予定

- [ ] GitLab APIを使った自動バージョンチェック
- [ ] ビルド失敗時の自動ロールバック
- [ ] 複数アーキテクチャ（arm64など）への対応
- [ ] CI/CDパイプラインの構築

## まとめ

これらのスクリプトにより、以下が自動化されました：

1. ✅ バージョンチェック
2. ✅ Makefileの更新
3. ✅ WANTLIB問題の自動回避
4. ✅ ファイル同期
5. ✅ クリーンビルド
6. ✅ パッケージ作成
7. ✅ テストインストール

次回から、新しいバージョンのPtyxisがリリースされたら、
`./build-ptyxis.sh`を実行するだけで、躓くことなくビルドできます！

---

**作成日**: 2025-11-07
**対象環境**: Fedora 43 → OpenBSD 7.8
