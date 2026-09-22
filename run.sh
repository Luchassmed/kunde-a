#!/usr/bin/env bash
set -euo pipefail

ENVNAME="${1:-sandbox}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
COMMON_DIR="$ROOT/common"

[ -e "$COMMON_DIR/.git" ] || { echo "[FEJL] common/ er ikke initialiseret. Koer: git submodule update --init --recursive"; exit 1; }

TARGET_BRANCH="main"
[ "$ENVNAME" = "sandbox" ] && TARGET_BRANCH="sandbox"

if [ -n "$(git -C "$COMMON_DIR" status --porcelain --untracked-files=no)" ]; then
  echo "[FEJL] common/ har lokale, ikke-committede aendringer - afbryder for ikke at miste dem."
  exit 1
fi

echo "Skifter common til branch '$TARGET_BRANCH' (miljoe: $ENVNAME)..."
git -C "$COMMON_DIR" fetch origin "$TARGET_BRANCH"
git -C "$COMMON_DIR" checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"

exec "$COMMON_DIR/run.sh" "$ENVNAME"
