# Setup

## Kør demoen første gang

```sh
cd ~/Git/autotest-framework-demo/kunde-a
git submodule update --init --recursive   # henter common/ ned på den pinnede commit
./demo.sh
```

Det er alt. Node er eneste krav — der er nul dependencies, så ingen `npm install`.

Er `common/` tom, er det altid fordi `git submodule update --init --recursive`
mangler. Et submodule følger ikke automatisk med et `git clone` eller et
`git checkout`.

## På en anden maskine

```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
```

Glemte du `--recurse-submodules`, så kør `git submodule update --init --recursive`
bagefter.

## Skift mellem miljø-versioner

```sh
git checkout sandbox                      # sandbox: common pinnet til v1.1.0
git submodule update --init --recursive
git -C common describe --tags             # → v1.1.0

git checkout main                         # prod: common pinnet til v1.0.0
git submodule update --init --recursive
git -C common describe --tags             # → v1.0.0
```

`git submodule update` efter hvert branch-skift er ikke til at komme udenom —
branchen skifter pin, men flytter ikke selve koden i `common/`.

## Valgfrit: den rigtige Playwright-test

Kun `login` er implementeret som rigtig test. Uden Playwright installeret bliver
den rapporteret som `skipped` — den fejler ikke.

```sh
npm install playwright && npx playwright install chromium
node common/runner/index.js --config config/prod.json --kunde-rod . --real
```

## Hvad der allerede er gjort

Begge repoer er bygget, committet, tagget og pushet:

- `isc-test-common` — indhold på `main`, tags `v1.0.0` og `v1.1.0` pushet
- `kunde-a` — `main` med `common/` pinnet til v1.0.0, `sandbox` pinnet til v1.1.0,
  begge branches pushet

## Hvis det skal bygges op fra bunden igen

Rækkefølgen betyder noget: `git submodule add` med en HTTPS-URL kloner fra GitHub,
så **common skal være pushet før kunderepoet kan pinne den**.

```sh
# 1. Fælles repo: indhold, to versioner, to tags
cd isc-test-common
git add -A && git commit -m "Runner, rapportformat og basale test cases"
git tag v1.0.0
#    ... ret approval.js så den håndterer den nye ISC-adfærd ...
git add -A && git commit -m "approval.js v1.1.0"
git tag v1.1.0
git push origin main
git push origin --tags          # NB: --follow-tags pusher ikke lightweight tags

# 2. Kunderepo: indhold på main
cd ../kunde-a
git add -A && git commit -m "Config, kundespecifik test, wrapper, scheduler, dokumentation"

# 3. Tilføj submodulet og pin det til v1.0.0 = prod
git submodule add https://github.com/Luchassmed/isc-test-common.git common
git -C common checkout v1.0.0
git add common .gitmodules
git commit -m "Pin common til v1.0.0 (prod)"
git push origin main

# 4. Sandbox-branch med den nyere version
git checkout -b sandbox
git -C common checkout v1.1.0
git add common
git commit -m "Pin common til v1.1.0 (sandbox)"
git push -u origin sandbox

# 5. Tilbage til udgangspunktet
git checkout main
git submodule update --init --recursive
```

## Ting du selv skal tage stilling til

- **Repoerne er public.** Til demoen er det uden betydning — der er kun dummy-data —
  men før noget kundevendt lægges i `kunde-a`, gør dem private:
  `gh repo edit Luchassmed/kunde-a --visibility private --accept-visibility-change-consequences`
  (og tilsvarende for `isc-test-common`).
- **`.ps1`-filerne er ikke afprøvet.** Der er ingen PowerShell på denne maskine, så
  `wrapper.ps1` og `demo.ps1` er skrevet som modstykker til bash-versionerne og
  gennemlæst, men ikke kørt. Skal demoen vises på Windows, så kør dem igennem én gang
  først.
