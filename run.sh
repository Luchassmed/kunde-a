#!/usr/bin/env bash
set -euo pipefail

# Hele scriptet ligger i en funktion og kaldes paa sidste linje: bash har dermed laest alt
# ind i hukommelsen, foer kunde-repoets branch skiftes (og filen evt. aendres under os).
# Hold run.sh/run.bat/run-nightly.ps1 ens paa alle branches.
main() {
  local ENVNAME="${1:-sandbox}"
  local ROOT; ROOT="$(cd "$(dirname "$0")" && pwd)"
  local COMMON_DIR="$ROOT/common"

  [ -e "$COMMON_DIR/.git" ] || { echo "[FEJL] common/ er ikke initialiseret. Koer: git submodule update --init --recursive"; exit 1; }

  local TARGET_BRANCH="main"
  [ "$ENVNAME" = "sandbox" ] && TARGET_BRANCH="sandbox"

  # common-pegeren flytter sig ved hver koersel, derfor --ignore-submodules for kunde-repoet.
  if [ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no --ignore-submodules)" ]; then
    echo "[FEJL] kunde-repoet har lokale, ikke-committede aendringer - afbryder for ikke at miste dem."
    exit 1
  fi
  if [ -n "$(git -C "$COMMON_DIR" status --porcelain --untracked-files=no)" ]; then
    echo "[FEJL] common/ har lokale, ikke-committede aendringer - afbryder for ikke at miste dem."
    exit 1
  fi

  echo "Skifter kunde-repo og common til branch '$TARGET_BRANCH' (miljoe: $ENVNAME)..."
  git -C "$ROOT" fetch origin "$TARGET_BRANCH"
  git -C "$ROOT" checkout "$TARGET_BRANCH"
  git -C "$ROOT" merge --ff-only "origin/$TARGET_BRANCH"
  git -C "$COMMON_DIR" fetch origin "$TARGET_BRANCH"
  git -C "$COMMON_DIR" checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"

  exec "$COMMON_DIR/run.sh" "$ENVNAME"
}

main "$@"
