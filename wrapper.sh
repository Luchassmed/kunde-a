#!/bin/sh
# Det scheduleren kalder hver nat:  ./wrapper.sh sandbox|prod
#
# Bemærk: der er IKKE 'set -e' omkring git-trinnene med vilje. Hvis kundens vært
# ikke kan nå GitHub, skal natten stadig testes på den kode der allerede ligger
# lokalt. En fejlet opdatering må aldrig betyde at der ingen test blev kørt.

MILJO="$1"
if [ "$MILJO" != "sandbox" ] && [ "$MILJO" != "prod" ]; then
  echo "Brug: $0 sandbox|prod"
  exit 2
fi

ROD=$(cd "$(dirname "$0")" && pwd)
cd "$ROD" || exit 2
DATO=$(date +%Y-%m-%d)
RAPPORT="results/$MILJO/$DATO.json"

# 1-3. Hent nyeste kode. Fejler det, logges en advarsel og vi kører videre.
echo "→ Opdaterer kode ..."
git pull --quiet || echo "  ADVARSEL: git pull fejlede — kører videre på lokal kode."
git submodule update --init --recursive --quiet || echo "  ADVARSEL: submodule update fejlede — kører videre på lokal version af common."

# 4-6. Kør testene og skriv rapporten.
node common/runner/index.js --config "config/$MILJO.json" --kunde-rod "$ROD" --out "$RAPPORT"
KODE=$?

# 7. Aflevering til PwC er ikke bygget endnu — her ville rapporten blive sendt.
echo "  POST → PwC resultat-API (simuleret): $RAPPORT"

# 8. Exit code følger resultatet, så scheduleren kan se om natten gik godt.
exit $KODE
