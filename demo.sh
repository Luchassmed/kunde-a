#!/bin/sh
# Hele historien på ~2 minutter.  Kør:  ./demo.sh
#
# Efterlader repoet på main, som det stod da demoen begyndte.

cd "$(dirname "$0")" || exit 1

overskrift() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════════"
  echo "  $1"
  echo "═══════════════════════════════════════════════════════════════════"
}

# Venter kun når nogen sidder og kigger — så scriptet også kan køre uovervåget.
pause() { [ -t 0 ] && { printf "\n  [Enter for at fortsætte] "; read -r _; }; }

# Start altid fra prod-tilstanden, også hvis en tidligere kørsel blev afbrudt
# midt i demoen. Ellers fortæller trin 2 og 3 den forkerte historie.
git checkout --quiet main
git submodule update --init --recursive --quiet

overskrift "TRIN 1 — Git-strukturen"
echo "  Branch:            $(git branch --show-current)"
echo "  Submodule common:  $(git submodule status common)"
echo "  Pinnet version:    $(git -C common describe --tags)"
echo ""
echo "  Kundens eget repo indeholder config og kundespecifikke tests."
echo "  Runner og basale tests kommer fra PwC's fælles repo via submodulet."
pause

overskrift "TRIN 2 — Prod kører grønt (ISC 2026.09, common v1.0.0)"
./wrapper.sh prod
echo "  Exit code: $?"
pause

overskrift "TRIN 3 — Samme testversion mod sandbox, hvor ISC ER opdateret"
echo "  SailPoint har opdateret sandbox til 2026.10 nogle dage før prod."
echo ""
./wrapper.sh sandbox
echo "  Exit code: $?  ← det er meningen. Det er alarmen kunden får."
pause

overskrift "TRIN 4 — Pin sandbox til en ny version af de fælles tests"
git checkout --quiet sandbox
git submodule update --init --recursive --quiet
echo "  Branch:            $(git branch --show-current)"
echo "  Submodule common:  $(git submodule status common)"
echo "  Pinnet version:    $(git -C common describe --tags)   ← ny version"
echo ""
echo "  Prod ligger urørt på main og kører stadig v1.0.0."
pause

overskrift "TRIN 5 — Sandbox er grøn igen"
./wrapper.sh sandbox
echo "  Exit code: $?"
pause

overskrift "TRIN 6 — Rapporten"
cat "results/sandbox/$(date +%Y-%m-%d).json"
pause

overskrift "TRIN 7 — Sådan driver scheduleren det"
cat scheduler/cron.txt
echo ""
echo "  Præcis samme kald som demoen lige lavede — bare kl. 01 og 02 om natten,"
echo "  på kundens egen vært."

# Efterlad repoet som det stod.
git checkout --quiet main
git submodule update --init --recursive --quiet
echo ""
echo "  (Repoet er sat tilbage til main / prod.)"
echo ""
