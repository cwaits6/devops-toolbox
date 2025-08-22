#!/usr/bin/env bash
set -euo pipefail

#========= EDIT ME =========#
OLD_HOST="oldgithost.com"
NEW_HOST="newgithost.com"
ROOT_DIR="$HOME/repos" # where to start scanning for repos
DRY_RUN=true           # set to true to preview changes
#======= END EDIT ME =======#

while IFS= read -r -d '' GITDIR; do
  REPO="${GITDIR%/.git}"
  cd "$REPO" || continue

  URL="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$URL" ]] || { cd - >/dev/null || continue; }
  [[ "$URL" == *"$OLD_HOST"* ]] || { cd - >/dev/null || continue; }

  case "$URL" in
  # scp-like: git@host:path
  *@*:*)
    userhost="${URL%%:*}" # left side before :
    path="${URL#*:}"      # right side after :
    user="${userhost%@*}"
    host="${userhost#*@}"
    if [[ "$host" == "$OLD_HOST" ]]; then
      NEW_URL="${user}@${NEW_HOST}:${path}"
    fi
    ;;
  # scheme:// style (http, https, ssh, etc.)
  *://*)
    proto="${URL%%://*}://"
    rest="${URL#*://}"
    userhost="${rest%%/*}"
    path="/${rest#*/}"
    if [[ "$userhost" == *"@"* ]]; then
      user="${userhost%@*}@"
      host="${userhost#*@}"
    else
      user=""
      host="$userhost"
    fi
    if [[ "$host" == "$OLD_HOST" ]]; then
      NEW_URL="${proto}${user}${NEW_HOST}${path}"
    fi
    ;;
  # fallback
  *)
    NEW_URL="${URL/$OLD_HOST/$NEW_HOST}"
    ;;
  esac

  if [[ -n "${NEW_URL:-}" && "$NEW_URL" != "$URL" ]]; then
    echo "✔ $REPO"
    echo "    $URL"
    echo " -> $NEW_URL"
    echo ""
    if [[ "$DRY_RUN" != "true" ]]; then
      git remote set-url origin "$NEW_URL"
    fi
  fi

  cd - >/dev/null || true
done < <(find "$ROOT_DIR" -type d -name .git -print0)

# Optional safety net (uncomment to enable):
# git config --global url."https://$NEW_HOST/".insteadOf "https://$OLD_HOST/"
# git config --global url."ssh://git@$NEW_HOST/".insteadOf "ssh://git@$OLD_HOST/"
