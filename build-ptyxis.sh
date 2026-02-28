#!/bin/bash
#
# Ptyxis for OpenBSD - 自動ビルドスクリプト
#
# このスクリプトは、Ptyxisの新バージョンを自動的にビルドします。
# 今回躓いたポイント（WANTLIB問題など）を自動的に回避します。

set -e  # エラーが発生したら停止

OPENBSD_HOST="openbsd77"
WORK_DIR="/home/ikeda/OpenBSD-Ptyxis"
REMOTE_PORT_DIR="/usr/ports/x11/ptyxis"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 現在のバージョンを取得
get_current_version() {
    grep "^V =" "$WORK_DIR/openbsd-port/Makefile" | awk '{print $3}'
}

# 最新バージョンを取得（WebFetch等で確認）
check_latest_version() {
    log_info "最新バージョンを確認中..."
    log_warn "手動で https://gitlab.gnome.org/chergert/ptyxis/-/tags を確認してください"

    CURRENT_VERSION=$(get_current_version)
    log_info "現在のバージョン: $CURRENT_VERSION"

    read -p "新しいバージョンでビルドしますか？ (バージョン番号を入力、Enterでスキップ): " NEW_VERSION

    if [ -z "$NEW_VERSION" ]; then
        log_info "現在のバージョン $CURRENT_VERSION でビルドを続行します"
        VERSION=$CURRENT_VERSION
    else
        log_info "バージョンを $NEW_VERSION に更新します"
        VERSION=$NEW_VERSION

        # Makefileを更新
        sed -i.bak "s/^V =.*$/V =\t\t$NEW_VERSION/" "$WORK_DIR/openbsd-port/Makefile"
        log_info "Makefileを更新しました"
    fi
}

# WANTLIBが存在しないことを確認（今回の問題の回避）
verify_makefile() {
    log_info "Makefileの検証中..."

    if grep -q "^WANTLIB" "$WORK_DIR/openbsd-port/Makefile"; then
        log_error "Makefileに WANTLIB が含まれています！"
        log_error "OpenBSD 7.8以降では、WANTLIBの自動検出を推奨します"
        log_warn "WANTLIB行を削除してください、または続行しますか？ [y/N]"
        read -p "" CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    else
        log_info "OK: WANTLIBは自動検出に設定されています"
    fi
}

# ファイルをOpenBSDに同期
sync_to_openbsd() {
    log_info "OpenBSDにファイルを同期中..."

    # Makefile
    scp "$WORK_DIR/openbsd-port/Makefile" "$OPENBSD_HOST:$REMOTE_PORT_DIR/" || {
        log_error "Makefileの同期に失敗しました"
        exit 1
    }

    # patches
    scp "$WORK_DIR/openbsd-port/patches/"* "$OPENBSD_HOST:$REMOTE_PORT_DIR/patches/" || {
        log_error "パッチの同期に失敗しました"
        exit 1
    }

    log_info "ファイル同期完了"
}

# OpenBSD上でビルド
build_on_openbsd() {
    log_info "OpenBSD上でビルドを開始..."

    # クリーンビルド
    log_info "Step 1/5: クリーンアップ..."
    ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && make clean=dist" || {
        log_warn "クリーンアップで警告が出ましたが続行します"
    }

    # ソースのダウンロードとチェックサム更新
    log_info "Step 2/5: ソースのダウンロードとチェックサム更新..."
    ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && make fetch && make makesum" || {
        log_error "ソースのダウンロードに失敗しました"
        exit 1
    }

    # パッチ適用
    log_info "Step 3/5: パッチ適用..."
    ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && make patch" || {
        log_error "パッチの適用に失敗しました"
        log_error "新しいバージョンでパッチの更新が必要な可能性があります"
        exit 1
    }

    # ビルド
    log_info "Step 4/5: コンパイル中（時間がかかります）..."
    ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && make build" || {
        log_error "ビルドに失敗しました"
        log_error "ビルドログを確認してください"
        exit 1
    }

    # パッケージ作成
    log_info "Step 5/5: パッケージ作成..."
    ssh "$OPENBSD_HOST" "cd $REMOTE_PORT_DIR && sudo make package" || {
        log_error "パッケージ作成に失敗しました"
        exit 1
    }

    log_info "ビルド完了！"
}

# 動作確認
verify_build() {
    log_info "ビルド結果を確認中..."

    ssh "$OPENBSD_HOST" "ls -lh $REMOTE_PORT_DIR/../../packages/amd64/all/ptyxis-*.tgz" || {
        log_error "パッケージが見つかりません"
        exit 1
    }

    log_info "パッケージをFedoraにコピー中..."
    scp "$OPENBSD_HOST:/usr/ports/packages/amd64/all/ptyxis-$VERSION.tgz" "$WORK_DIR/" || {
        log_error "パッケージのコピーに失敗しました"
        exit 1
    }

    log_info "完了！パッケージ: $WORK_DIR/ptyxis-$VERSION.tgz"
}

# テストインストール（オプション）
test_install() {
    log_warn "テストインストールを実行しますか？ [y/N]"
    read -p "" DO_INSTALL

    if [ "$DO_INSTALL" = "y" ]; then
        log_info "既存のptyxisを削除中..."
        ssh "$OPENBSD_HOST" "sudo pkg_delete ptyxis || true"
        ssh "$OPENBSD_HOST" "sudo rm -f /usr/local/bin/ptyxis /usr/local/libexec/ptyxis-agent"

        log_info "新しいパッケージをインストール中..."
        ssh "$OPENBSD_HOST" "sudo pkg_add -Dunsigned /usr/ports/packages/amd64/all/ptyxis-$VERSION.tgz" || {
            log_error "インストールに失敗しました"
            exit 1
        }

        log_info "バージョン確認..."
        ssh "$OPENBSD_HOST" "ptyxis --version" || {
            log_error "実行に失敗しました"
            exit 1
        }

        log_info "テストインストール成功！"
    fi
}

# メイン処理
main() {
    log_info "=== Ptyxis for OpenBSD - 自動ビルドスクリプト ==="
    log_info ""

    # バージョンチェック
    check_latest_version

    # Makefile検証
    verify_makefile

    # 同期
    sync_to_openbsd

    # ビルド
    build_on_openbsd

    # 確認
    verify_build

    # テストインストール（オプション）
    test_install

    log_info ""
    log_info "=== すべての処理が完了しました ==="
    log_info "パッケージ: $WORK_DIR/ptyxis-$VERSION.tgz"
}

# スクリプト実行
main "$@"
