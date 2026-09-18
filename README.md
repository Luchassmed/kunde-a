# kunde-a

Kundens eget repo. Det fælles testframework ligger i `common/` som et git-submodule
(repo: `isc-test-common`), mens dette repo kun har kundens miljø-konfiguration
(`config/*.properties`) og evt. kundespecifikke tests (`tests/manifest.txt`).

## Hvorfor branches, ikke tags

Leverandøren ruller ændringer ud på sandbox nogle dage før pre-prod/prod, så koden i
`common` skal kunne se forskelligt ud pr. miljø. Det styres via to branches i
`isc-test-common`: `main` og `sandbox`. Kunderepoet peger på én af dem ad gangen via
`branch = ...` i `.gitmodules`.

## Skift miljø

```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
```

For at skifte hvilken branch af `common` der bruges — ret `branch = main` til
`branch = sandbox` (eller omvendt) i `.gitmodules`, og kør:

```sh
git submodule sync -- common
git submodule update --init --remote common
```

Kør derefter fx `.\run.bat sandbox` for at se, at både banner og testliste ændrer
sig alt efter hvilken branch af `common` der er hentet.

## Opsætning uden Docker (Scenarie C: kunden kører selv)

Denne vej kræver ikke Docker — kun Git og Node.js (LTS) installeret på maskinen, der
skal køre testene. Det simulerer den model hvor kunden selv henter og drifter
runneren, uden PwC har adgang til maskinen.

Forudsætninger (én gang):

```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
cd kunde-a
common\setup.bat        # Windows
common/setup.sh         # macOS / Linux
```

`setup` installerer Playwright-pakken og de browsere, den skal bruge — det svarer til
den Docker-images allerede har indbygget, men skal her hentes eksplicit, da der ikke
er noget forudbygget image at trække på.

Kørsel (hver gang):

```sh
common\run.bat sandbox   # Windows
common/run.sh sandbox    # macOS / Linux
```

Miljøets værdier (`tenant_url` m.fl.) hentes stadig fra `config/sandbox.properties` —
samme konfigurationsfil som Docker- og GitHub Actions-vejen bruger. Der er ingen
forskel i *hvad* der testes, kun i *hvor* det kører.
