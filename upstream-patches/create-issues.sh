#!/bin/sh
# create-issues.sh — Create Ptyxis upstream bug issues on GNOME GitLab
#
# Usage:
#   export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
#   ./create-issues.sh
#
# Output:
#   Prints the created issue numbers (needed for create-mr.sh)

set -e

GITLAB_URL="https://gitlab.gnome.org/api/v4"
PROJECT_ID="29370"   # chergert/ptyxis

# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------
if [ -z "$GITLAB_TOKEN" ]; then
  if [ -f "$HOME/.env-ptyxis-upstream" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.env-ptyxis-upstream"
  fi
fi

if [ -z "$GITLAB_TOKEN" ]; then
  echo "ERROR: GITLAB_TOKEN is not set." >&2
  echo "  export GITLAB_TOKEN=\"glpat-xxxxxxxxxxxxxxxxxxxx\"" >&2
  echo "  or save it to ~/.env-ptyxis-upstream" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required but not found." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helper: POST to GitLab API
# Returns the issue number on success, exits on failure.
# ---------------------------------------------------------------------------
create_issue() {
  title="$1"
  description="$2"

  response=$(curl -s -w "\n%{http_code}" \
    --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$(printf '{"title":%s,"description":%s}' \
        "$(printf '%s' "$title"       | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
        "$(printf '%s' "$description" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')")" \
    "$GITLAB_URL/projects/$PROJECT_ID/issues")

  body=$(printf '%s' "$response" | head -n -1)
  http_code=$(printf '%s' "$response" | tail -n 1)

  if [ "$http_code" != "201" ]; then
    echo "ERROR: GitLab API returned HTTP $http_code" >&2
    echo "$body" >&2
    exit 1
  fi

  printf '%s' "$body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['iid'])"
}

# ---------------------------------------------------------------------------
# Issue 1: zoom_font_scales array typo
# ---------------------------------------------------------------------------
TITLE1="tab: zoom_font_scales array has typo causing wrong maximum zoom level"
DESC1='## Summary

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

Confirmed in 49.2 and 49.3.'

# ---------------------------------------------------------------------------
# Issue 2: NULL dereference in ptyxis_path_expand
# ---------------------------------------------------------------------------
TITLE2="util: NULL pointer dereference in ptyxis_path_expand() when wordexp fails"
DESC2='## Summary

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

Confirmed in 49.2 and 49.3.'

# ---------------------------------------------------------------------------
# Create the issues
# ---------------------------------------------------------------------------
echo "Creating Issue 1: $TITLE1"
ISSUE1=$(create_issue "$TITLE1" "$DESC1")
echo "  -> Created issue #$ISSUE1"
echo "     https://gitlab.gnome.org/chergert/ptyxis/-/issues/$ISSUE1"
echo ""

echo "Creating Issue 2: $TITLE2"
ISSUE2=$(create_issue "$TITLE2" "$DESC2")
echo "  -> Created issue #$ISSUE2"
echo "     https://gitlab.gnome.org/chergert/ptyxis/-/issues/$ISSUE2"
echo ""

echo "Done. Issue numbers for create-mr.sh:"
echo "  ./create-mr.sh $ISSUE1 $ISSUE2"
