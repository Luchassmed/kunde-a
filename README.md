# kunde-a — automatisk natlig test af SailPoint ISC

Proof-of-concept til internt møde. Formålet er at **vise en arkitektur**, ikke at
levere et færdigt produkt.

## Problemet vi løser

SailPoint opdaterer ISC løbende. En opdatering kan bryde noget hos kunden — et
godkendelsesflow, en provisionering — uden at nogen opdager det før en bruger
ringer. SailPoint opdaterer kundens **sandbox nogle dage før prod**, så der findes
et vindue hvor problemet kan fanges før det rammer produktionen.

Frameworket kører kundens vigtigste ISC-flows igennem hver nat i begge miljøer og
sender resultatet til PwC, så vi kan advisere kunden i tide.

Det stiller ét konkret krav til arkitekturen: **sandbox og prod skal kunne køre
forskellige versioner af de samme test cases samtidigt** — for i det vindue er de
to miljøer ikke ens.

## Hvad demoen viser

- Fælles PwC-kode og kundespecifik kode i hvert sit repo, koblet med et git-submodule
- At submodulet kan pinnes til forskellige versioner pr. miljø — og hvorfor det er nødvendigt
- En runner der kører testene og producerer en rapport i et fast format
- At en scheduler (cron / Windows Task Scheduler) driver hele flowet
- At en fejlet kodeopdatering ikke aflyser nattens test

## Hvad demoen IKKE viser

- **Der er ingen kontakt til SailPoint.** Alle testresultater er simulerede. Én test
  (`login`) kan køre som rigtig Playwright-test, men er slået fra som standard.
- **Ingen evaluering og ingen alarmering.** Rapporten bliver skrevet til en fil og
  "afleveret" med en `echo`. Der er ingen modtager, ingen historik, ingen advisering.
- **Ingen secrets-håndtering.** Der ligger en `example.env` med placeholders. Hvordan
  rigtige credentials havner på kundens vært er ikke løst.
- **Intet om drift**: ingen CI/CD, ingen overvågning af at rapporten faktisk ankom,
  ingen onboarding af kunde nr. 2.

## Hvordan det hænger sammen

```
                        ┌──────────────────────────────────────┐
                        │  isc-test-common          (PwC ejer) │
                        │  runner/  lib/  testcases/basic/      │
                        │  tags:  v1.0.0    v1.1.0              │
                        └──────────────┬───────────────────────┘
                                       │
                    git submodule — pinnet til ÉN commit ad gangen
                                       │
                 ┌─────────────────────┴─────────────────────┐
                 │                                           │
      ┌──────────▼───────────────┐            ┌──────────────▼───────────┐
      │  kunde-a @ main   PROD   │            │  kunde-a @ sandbox       │
      │                          │            │                          │
      │  common/  → v1.0.0       │            │  common/  → v1.1.0       │
      │  config/prod.json        │            │  config/sandbox.json     │
      │  testcases/custom/       │            │  testcases/custom/       │
      │  secrets/   (ikke i git) │            │  secrets/   (ikke i git) │
      └──────────┬───────────────┘            └──────────────┬───────────┘
                 │                                           │
                 └─────────────────────┬─────────────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │  SCHEDULER (kundens vært)   │
                        │  cron / Task Scheduler      │
                        │  01:00 sandbox  02:00 prod  │
                        └──────────────┬──────────────┘
                                       │  ./wrapper.sh <miljø>
                        ┌──────────────▼──────────────┐
                        │  WRAPPER                    │
                        │  git pull + submodule update│
                        │  (fejler det → kør videre)  │
                        └──────────────┬──────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │  RUNNER  (fra common/)      │
                        │  udfører · måler · rapporterer │
                        │  — vurderer ingenting       │
                        └──────────────┬──────────────┘
                                       │
                     ┌─────────────────┴─────────────────┐
                     ▼                                   ▼
        results/<miljø>/<dato>.json          POST → PwC resultat-API
              (fast JSON-format)                   (simuleret)
```

To ting er værd at bemærke i diagrammet:

1. **Runneren kommer fra PwC's repo, men kører hos kunden.** Vi vedligeholder ét sted
   og udruller til mange.
2. **Runneren vurderer ikke om et resultat er acceptabelt.** Den udfører og
   rapporterer. Vurderingen sker nedstrøms hos PwC, på rapporten. Det er dét der gør
   at vi kan ændre alarmeringsregler for alle kunder uden at røre kode hos nogen af dem.

## Kør demoen

```sh
./demo.sh
```

Den kører hele historien igennem med overskrifter mellem trinnene og venter på Enter
undervejs. Enkeltdele:

```sh
./wrapper.sh prod        # ét miljø, som scheduleren ville gøre det
./wrapper.sh sandbox
cat results/prod/$(date +%Y-%m-%d).json
```

Kræver Node. Ingen `npm install` — der er nul dependencies.

## Versionering pr. miljø

Det er kernen i det hele.

Et submodule peger på **én bestemt commit** i det fælles repo. Derfor kan et checkout
af `kunde-a` kun køre én version af de fælles test cases ad gangen. Vi løser det med
**en branch pr. miljø**, hvor forskellen udelukkende er hvilken commit `common/`
peger på:

| Branch | `common/` pinnet til | Repræsenterer |
|---|---|---|
| `main` | `v1.0.0` | Prod — ISC 2026.09, urørt |
| `sandbox` | `v1.1.0` | Sandbox — ISC 2026.10, testene tilpasset |

Skift mellem dem:

```sh
git checkout sandbox
git submodule update --init --recursive   # ← nødvendig: den flytter common/ til den pinnede commit
git -C common describe --tags             # v1.1.0
```

Glemmer man `submodule update`, står `common/` stadig på den gamle commit — branchen
er skiftet, men koden er ikke. Derfor gør `wrapper.sh` det hver eneste nat.

### Hvorfor det er mekanismen der redder prod

Demoens forløb, i tre kørsler:

1. **Prod på `main` (v1.0.0)** → alt grønt. Prod kører stadig ISC 2026.09.
2. **Sandbox på `main` (v1.0.0)** → `approval` **fejler**. SailPoint har opdateret
   sandbox til 2026.10 og indført et ekstra bekræftelsestrin, som testen ikke kender.
   *Det er præcis den alarm kunden betaler for.*
3. **Sandbox på `sandbox` (v1.1.0)** → grøn igen. Testen er tilpasset det nye flow.

Undervejs er prod aldrig blevet rørt. Når SailPoint senere opdaterer prod, flytter vi
`main` til v1.1.0 — en bevidst handling, ikke noget der sker af sig selv.

### Konsekvensen i drift

Et git-checkout kan kun stå på én branch ad gangen. Så i drift er der **ét checkout
pr. miljø** af samme repo, i hver sin mappe, på hver sin branch. Det er derfor
`scheduler/cron.txt` peger på to forskellige stier.

### Hvorfor submodule-modellen

- **Central vedligeholdelse.** Runner, rapportformat og de basale test cases rettes
  ét sted hos PwC og kan udrulles til alle kunder.
- **Kontrolleret udrulning.** Kunden får aldrig en ændring de ikke har pinnet. En
  commit i det fælles repo rammer ingen automatisk.
- **Tydelig grænse.** Kundens config, credentials og egne test cases ligger i kundens
  repo og røres aldrig af en opdatering af common. `testcases/custom/` er kundens.
- **Sporbarhed.** Rapporten indeholder `common_version` — vi kan altid se præcis
  hvilken kode der producerede et resultat.

### Alternativer — valget er ikke truffet

- **Separat klon pr. miljø** i stedet for branches. Enklere at forklare, men så skal
  to klon holdes opdateret, og forskellen mellem miljøerne står ikke længere i git.
- **Versionsvalg inde i common** via et "feature map" — én kodebase der selv slår op
  hvilken ISC-release miljøet kører og vælger adfærd derefter. Færre repoer at holde
  styr på, men logikken bliver mere indviklet, og man mister den skarpe "prod er
  pinnet og rører sig ikke"-garanti.

Branch-modellen er valgt her fordi den demonstrerer mekanismen tydeligst. Hvad vi
faktisk skal bygge på, er et åbent spørgsmål.

## Kendte begrænsninger og åbne spørgsmål

**Begrænsninger i demoen**

- Alt er mock. Ingen rigtig ISC-integration, ingen rigtige credentials.
- Repoerne er public på GitHub i demoen. I virkeligheden skal de være private.
- `.ps1`-filerne er skrevet som modstykker til bash-versionerne, men er ikke afprøvet
  på en Windows-maskine.
- Testdata ryddes op med en `cleanup()` der ikke gør noget rigtigt. I praksis
  efterlader natlige tests spor i kundens tenant, og det skal håndteres.

**Åbne spørgsmål vi skal svare på før det bliver et produkt**

- **Hvem ejer og godkender et nyt tag i common?** Når en ISC-release bryder noget hos
  fem kunder, hvem retter testen, og hvem beslutter at prod må flytte pin?
- **Hvordan opdager vi at en rapport udeblev?** Lige nu ville en død vært se ud som
  stilhed. Manglende svar skal være en alarm i sig selv.
- **Hvordan skelner vi "ISC har ændret sig" fra "kunden har ændret sin konfiguration"?**
  Begge dele får testen til at fejle, men kun det ene er vores at reagere på.
- **Hvordan kommer credentials sikkert på kundens vært**, og hvem roterer dem?
- **Skalering:** hvad koster det at onboarde kunde nr. 20? Hvis hver kunde har sit eget
  repo, sin egen vært og sine egne pins, skal der være et sted vi kan se dem alle.
- **Kunder med flere end to miljøer** — modellen skal kunne udvides til fx dev/test/prod.
