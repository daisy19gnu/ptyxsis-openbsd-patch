# 上流への提出方法

このディレクトリには Ptyxis の上流（GNOME GitLab）に提出すべき
プラットフォーム共通のバグ修正パッチが含まれています。

## 提出先

**プロジェクト**: https://gitlab.gnome.org/chergert/ptyxis
**Issues**: https://gitlab.gnome.org/chergert/ptyxis/-/issues
**Merge Requests**: https://gitlab.gnome.org/chergert/ptyxis/-/merge_requests

## 提出するパッチ

| ファイル | 種別 | 優先度 |
|----------|------|--------|
| `0001-fix-zoom_font_scales-array-typo.patch` | バグ修正（全プラットフォーム） | 高 |
| `0002-fix-null-deref-in-ptyxis_path_expand.patch` | バグ修正（全プラットフォーム） | 高 |

---

## 事前準備

### 1. GNOME GitLab アカウント作成

https://gitlab.gnome.org/users/sign_in から GitLab.com のアカウントで
サインインするか、新規アカウントを作成します。

### 2. Personal Access Token の取得

https://gitlab.gnome.org/-/profile/personal_access_tokens にアクセスし、
以下のスコープを持つトークンを作成します：

- `api` （Issue・MR の作成に必要）
- `read_repository` / `write_repository` （MR用のフォーク操作に必要）

トークンを環境変数に設定：
```sh
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
```

または `~/.env-ptyxis-upstream` ファイルに保存：
```sh
echo 'export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"' > ~/.env-ptyxis-upstream
chmod 600 ~/.env-ptyxis-upstream
```

---

## 提出方法 A: Issue のみ（最短）

コード変更なしでバグを報告するだけの場合。

```sh
cd upstream-patches/
./create-issues.sh
```

スクリプトが対話的に2つの Issue を作成します。

---

## 提出方法 B: Issue + Merge Request（推奨）

実際のコード修正をパッチとして提出する場合。

### ステップ 1: Issue を作成

```sh
./create-issues.sh
```

作成された Issue の番号をメモしておく（MR の説明文に記載するため）。

### ステップ 2: リポジトリをフォーク

```sh
./fork-and-prepare.sh
```

スクリプトが以下を自動実行します：
1. GNOME GitLab 上でフォークを作成
2. フォークをローカルにクローン
3. パッチを適用してコミット
4. フォークに push

### ステップ 3: Merge Request を作成

```sh
./create-mr.sh <issue1番号> <issue2番号>
# 例: ./create-mr.sh 123 124
```

---

## 提出方法 C: Web UI から手動提出

スクリプトを使わずに手動で提出する場合の手順です。

### Issue の作成

1. https://gitlab.gnome.org/chergert/ptyxis/-/issues/new を開く
2. 以下の内容で2件作成する（後述のテンプレート参照）

### MR の作成

1. https://gitlab.gnome.org/chergert/ptyxis/-/forks/new でフォーク作成
2. フォークをクローン:
   ```sh
   git clone https://gitlab.gnome.org/<あなたのユーザー名>/ptyxis.git
   cd ptyxis
   git checkout 49.3   # または main
   ```
3. ブランチを作成:
   ```sh
   git checkout -b fix/zoom-font-scales-typo
   ```
4. パッチを適用:
   ```sh
   git am ../upstream-patches/0001-fix-zoom_font_scales-array-typo.patch
   ```
5. プッシュ:
   ```sh
   git push origin fix/zoom-font-scales-typo
   ```
6. GitLab Web UI で MR を作成

---

## Issue テンプレート

### Issue 1: zoom_font_scales 配列のタイポ

**タイトル**: `tab: zoom_font_scales array has typo causing wrong maximum zoom level`

**本文**:
```
## Summary

`zoom_font_scales[]` in `src/ptyxis-tab.c` has a typo: `1,2` instead of `1.2`
in the last element.

## Details

In a C array initializer, the comma is the element separator, not the decimal
point. So `1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1,2,` creates **two**
elements:
- element [15] = `1.0 * 1.2^6 * 1` ≈ 2.986  (duplicate of element [14])
- element [16] = `2.0`              (unreachable extra element)

The intended value was `1.2^7` ≈ 3.583.

## Impact

- Maximum zoom level (index 15) shows the same scale as level 14
- The array has 17 elements instead of 16

## Fix

```diff
-  1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1,2,
+  1.0 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2 * 1.2,
```

## Affected versions

Confirmed in 49.2 and 49.3.
```

---

### Issue 2: ptyxis_path_expand の NULL 参照

**タイトル**: `util: NULL pointer dereference in ptyxis_path_expand() when wordexp fails`

**本文**:
```
## Summary

`ptyxis_path_expand()` in `src/ptyxis-util.c` dereferences a potentially NULL
pointer when `wordexp()` fails.

## Details

If `wordexp()` fails (e.g. WRDE_NOSPACE out of memory, invalid input), `ret`
remains NULL. The function then calls `g_path_is_absolute(ret)` with a NULL
argument, causing a crash.

Additionally, the function is documented to return "A newly allocated string"
but may return NULL if wordexp fails, violating the contract.

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

## Impact

On platforms where `wordexp()` is unavailable (e.g. OpenBSD), this causes a
crash when opening a new terminal tab with a custom working directory profile.
On Linux, the crash can occur when `wordexp()` fails due to memory pressure.

## Affected versions

Confirmed in 49.2 and 49.3.
```

---

## コミットメッセージのスタイル

Ptyxis は `subject: description` 形式を使用します：

```
tab: fix zoom_font_scales array typo
util: fix NULL dereference in ptyxis_path_expand()
```

詳細は上流の既存コミットを参照してください：
```sh
git log --oneline -20
```

---

## フォローアップ

提出後は以下を確認します：

1. CI が通過しているか（パイプラインバッジ）
2. メンテナ（chergert）からのフィードバックがないか
3. マージされたら `CLAUDE.md` の「適用済みパッチ」表を更新する
4. マージ後のバージョン（例: 49.4）ではパッチが不要になるため削除する
