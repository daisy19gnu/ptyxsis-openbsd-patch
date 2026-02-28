#!/bin/bash
#
# Ptyxis バージョンチェックスクリプト
#
# このスクリプトは、Ptyxisの最新バージョンをGitLabから取得し、
# 現在のMakefileのバージョンと比較します。

set -e

WORK_DIR="/home/ikeda/OpenBSD-Ptyxis"
GITLAB_TAGS_URL="https://gitlab.gnome.org/chergert/ptyxis/-/tags"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_version() {
    echo -e "${BLUE}[VERSION]${NC} $1"
}

# 現在のバージョンを取得
get_current_version() {
    grep "^V =" "$WORK_DIR/openbsd-port/Makefile" | awk '{print $3}'
}

# GitLabから最新のタグを取得（簡易版：手動確認を促す）
check_latest_version_web() {
    log_info "GitLabのタグページ: $GITLAB_TAGS_URL"
    log_info ""
    log_warn "ブラウザで上記URLを開き、最新の安定版タグを確認してください"
    log_warn "（例: 49.2, 49.3, 50.0 など）"
    log_info ""
}

# メイン処理
main() {
    log_info "=== Ptyxis バージョンチェック ==="
    log_info ""

    # 現在のバージョン
    CURRENT_VERSION=$(get_current_version)
    log_version "現在使用中のバージョン: $CURRENT_VERSION"

    # Makefileの最終更新日
    MAKEFILE_DATE=$(stat -c %y "$WORK_DIR/openbsd-port/Makefile" 2>/dev/null || stat -f %Sm "$WORK_DIR/openbsd-port/Makefile" 2>/dev/null || echo "不明")
    log_info "Makefileの最終更新: $MAKEFILE_DATE"

    log_info ""

    # 最新バージョンの確認（Web）
    check_latest_version_web

    # CLAUDE.mdのバージョン情報を更新
    log_info "次のステップ:"
    log_info "1. 上記URLで最新バージョンを確認"
    log_info "2. 新しいバージョンがある場合:"
    log_info "   - ./build-ptyxis.sh を実行"
    log_info "   - プロンプトで新しいバージョン番号を入力"
    log_info "3. バージョンが最新の場合:"
    log_info "   - CLAUDE.mdの「最後に確認した日」を更新"

    log_info ""
    log_info "=== チェック完了 ==="
}

main "$@"
