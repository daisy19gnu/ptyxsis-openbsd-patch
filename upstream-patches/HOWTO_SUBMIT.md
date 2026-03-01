# 上流への提出方法

このディレクトリには Ptyxis の上流（GNOME GitLab）に提出すべき
プラットフォーム共通のバグ修正パッチが含まれています。

## 提出先

- プロジェクト: https://gitlab.gnome.org/chergert/ptyxis
- Issues: https://gitlab.gnome.org/chergert/ptyxis/-/issues
- Merge Requests: https://gitlab.gnome.org/chergert/ptyxis/-/merge_requests

## 提出するパッチ

| ファイル | 種別 | 優先度 |
|----------|------|--------|
| `0001-fix-zoom_font_scales-array-typo.patch` | バグ修正（全プラットフォーム） | 高 |
| `0002-fix-null-deref-in-ptyxis_path_expand.patch` | バグ修正（全プラットフォーム） | 高 |

---

## 事前準備

### GNOME GitLab アカウント

https://gitlab.gnome.org/users/sign_in から GitLab.com アカウントでサインインするか、
新規アカウントを作成します。

### Personal Access Token

https://gitlab.gnome.org/-/profile/personal_access_tokens にアクセスし、
以下のスコープを持つトークンを作成します。

- `api` （Issue・MR の作成に必要）
- `read_repository` / `write_repository` （MR 用のフォーク操作に必要）

トークンを環境変数に設定するか、ファイルに保存します。

```sh
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
```

または:

```sh
echo 'export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"' > ~/.env-ptyxis-upstream
chmod 600 ~/.env-ptyxis-upstream
```

---

## 提出方法 A: Issue のみ（最短）

```sh
cd upstream-patches/
./create-issues.sh
```

スクリプトが対話的に 2 つの Issue を作成します。

---

## 提出方法 B: Issue + Merge Request（推奨）

### ステップ 1: Issue を作成

```sh
./create-issues.sh
```

作成された Issue の番号をメモしておきます（MR の説明文に記載するため）。

### ステップ 2: リポジトリをフォークしてパッチブランチを作成

```sh
./fork-and-prepare.sh
```

スクリプトが以下を自動実行します。

1. GNOME GitLab 上でフォークを作成（既存の場合はスキップ）
2. フォークをローカルにクローン（`./ptyxis-upstream-work/`）
3. パッチをブランチとして適用
4. フォークに push

### ステップ 3: Merge Request を作成

```sh
./create-mr.sh <issue1番号> <issue2番号>
# 例: ./create-mr.sh 123 124
```

---

## 提出方法 C: Web UI から手動提出

### Issue の作成

https://gitlab.gnome.org/chergert/ptyxis/-/issues/new を開き、
HOWTO_SUBMIT.md に記載のテンプレートを参考に 2 件作成します。

### MR の作成

```sh
# フォーク
# https://gitlab.gnome.org/chergert/ptyxis/-/forks/new

git clone https://gitlab.gnome.org/<your-username>/ptyxis.git
cd ptyxis

# ブランチ 1: zoom タイポ修正
git checkout -b fix/zoom-font-scales-typo
git am ../upstream-patches/0001-fix-zoom_font_scales-array-typo.patch
git push origin fix/zoom-font-scales-typo

# ブランチ 2: NULL 参照修正
git checkout main
git checkout -b fix/null-deref-path-expand
git am ../upstream-patches/0002-fix-null-deref-in-ptyxis_path_expand.patch
git push origin fix/null-deref-path-expand
```

GitLab Web UI で各ブランチから MR を作成します。

---

## Issue テンプレート

### Issue 1: zoom_font_scales 配列のタイポ

タイトル: `tab: zoom_font_scales array has typo causing wrong maximum zoom level`

```
## Summary

`zoom_font_scales[]` in `src/ptyxis-tab.c` has a typo: `1,2` instead of `1.2`
in the last element.

## Details

In a C array initializer, the comma is the element separator, not the decimal
point. So `1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1,2,` creates two
elements:
- element [15] = `1.0 * 1.2^6 * 1` approx 2.986  (duplicate of element [14])
- element [16] = `2.0`              (unreachable extra element)

The intended value was `1.2^7` approx 3.583.

## Fix

```diff
-  1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1,2,
+  1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2,
```

## Affected versions

Confirmed in 49.2 and 49.3.
```

### Issue 2: ptyxis_path_expand の NULL 参照

タイトル: `util: NULL pointer dereference in ptyxis_path_expand() when wordexp fails`

```
## Summary

`ptyxis_path_expand()` in `src/ptyxis-util.c` dereferences a potentially NULL
pointer when `wordexp()` fails.

## Details

If `wordexp()` fails (e.g. WRDE_NOSPACE, invalid input, or when unavailable),
`ret` remains NULL. The function then calls `g_path_is_absolute(ret)` with a
NULL argument, causing a crash.

## Fix

```diff
-  if (!g_path_is_absolute (ret))
+  if (ret != NULL && !g_path_is_absolute (ret))
     {
       g_autofree char *freeme = ret;
       ret = g_build_filename (g_get_home_dir (), freeme, NULL);
     }

   g_free (replace_home);
   g_free (escaped);

-  return ret;
+  return ret != NULL ? ret : g_strdup (path);
```

## Affected versions

Confirmed in 49.2 and 49.3.
```

---

## コミットメッセージのスタイル

Ptyxis は `subject: description` 形式を使用します。

```
tab: fix zoom_font_scales array typo
util: fix NULL dereference in ptyxis_path_expand()
```

---

## フォローアップ

提出後は以下を確認します。

1. CI が通過しているか（パイプラインバッジ）
2. メンテナ（chergert）からのフィードバックがないか
3. マージされたら該当パッチを `openbsd-port/patches/` から削除する
4. 次のリリースでパッチが含まれていることを確認する
