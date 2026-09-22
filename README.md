# kunde-a

Kundens eget repo. Det fælles testframework ligger i `common/` som et git-submodule
(repo: `isc-test-common`), mens dette repo kun har kundens miljø-konfiguration
(`config/*.properties`) og evt. kundespecifikke tests (`tests/manifest.txt`).

## Hvorfor branches, ikke tags

Leverandøren ruller ændringer ud på sandbox nogle dage før pre-prod/prod, så koden i
`common` skal kunne se forskelligt ud pr. miljø. Det styres via to branches i
`isc-test-common`: `main` og `sandbox`.

## Skift miljø

```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
```

`run.bat`/`run.sh` i denne mappe (**ikke** dem inde i `common/`) styrer automatisk
hvilken branch af `common` der bruges, ud fra miljø-argumentet:

```powershell
.\run.bat sandbox    # checker sandbox-branchen af common ud, laeser config\sandbox.properties
.\run.bat preprod    # checker main-branchen ud, laeser config\preprod.properties
.\run.bat prod       # checker main-branchen ud, laeser config\prod.properties
```

Kør uden argument, og den antager `sandbox`. Scriptet henter (`git fetch`) og skifter
branch (`git checkout`) i `common/` hver gang, før testene startes — miljø og kode
følges altså altid ad, uden et separat manuelt trin. Kør derfor altid **root-scriptet**
(`.\run.bat`), ikke `common\run.bat` direkte — det sidste antager bare at `common/`
allerede står på den rigtige branch og rører ikke ved den.

Har `common/` lokale, ikke-committede ændringer, afbryder scriptet med en fejl i
stedet for at overskrive dem — ryd op eller commit i `common/` selv for at fortsætte.

Dette gælder kun den native/Windows Server-kørsel. Docker- og GitHub Actions-vejen
bruger stadig `branch = ...` i `.gitmodules` (se `isc-test-common`s README) uændret.

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

Kørsel (hver gang) — brug root-scriptet, ikke `common\run.bat` direkte, så
branch-skiftet beskrevet ovenfor sker automatisk:

```sh
.\run.bat sandbox   # Windows
./run.sh sandbox    # macOS / Linux
```

Miljøets værdier (`tenant_url` m.fl.) hentes stadig fra `config/sandbox.properties` —
samme konfigurationsfil som Docker- og GitHub Actions-vejen bruger. Der er ingen
forskel i *hvad* der testes, kun i *hvor* det kører.

## Natlig kørsel uden GitHub Actions (Windows Task Scheduler)

`run-nightly.ps1` kører alle tre miljøer efter tur, logger hvert til
`logs\<tidsstempel>-<miljø>.log` (ikke committet, kun lokalt), og fejler aldrig
hængende — Playwright's rapport er sat til aldrig at popper selv op
(`open: 'never'`), netop fordi det ellers kan hænge for evigt ved en fejlet test
uden nogen til at trykke Ctrl+C.

Registrér som en planlagt opgave, der kører kl. 02:00 hver nat:

```powershell
schtasks /create /tn "ISC nattest - kunde-a" `
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:\sti\til\kunde-a\run-nightly.ps1`"" `
  /sc daily /st 02:00 /ru SYSTEM
```

- Kør kommandoen fra en PowerShell med administratorrettigheder.
- `/ru SYSTEM` kræver ingen adgangskode, men forudsætter at Node.js og Git er
  installeret systemdækkende (ikke kun for din egen brugerprofil) — ellers finder
  SYSTEM-kontoen dem ikke på PATH. Er det tilfældet, skift i stedet "run as"-konto
  til en dedikeret servicebruger via Task Scheduler-GUI'en (Egenskaber → Generelt),
  hvor adgangskoden indtastes i et maskeret felt i stedet for på kommandolinjen.
- Test opgaven med det samme uden at vente til kl. 02:00:
  `schtasks /run /tn "ISC nattest - kunde-a"`, og tjek bagefter `logs\`-mappen samt
  Task Scheduler-historikken for opgaven.
- Vil du kun teste ét miljø om natten i stedet for alle tre, tilføj
  `-Environments sandbox` til `/tr`-argumentet.

Alarmering/OTRS-integration ved fejl er ikke bygget endnu — lige nu er signalet at
tjekke Task Schedulers "Last Run Result" for opgaven, eller læse log-filerne.
