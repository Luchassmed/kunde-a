# kunde-a

Kundens eget repo. Det er dette link kunden får — resten følger med automatisk.

```
kunde-a/
  kunde-a.properties     Kundens egne værdier (tenant_url m.m.)
  common/                Submodule → isc-test-common (PwC's fælles repo)
```

## Sådan hænger det sammen

```
   PwC                              Kunden
   ───                              ──────

   isc-test-common                  kunde-a
   ├── run.sh                       ├── kunde-a.properties
   └── run.bat                      │      kunde=kunde-a
        │                           │      tenant_url=https://…
        │                           │
        │   git submodule           └── common/  ←── peger på én commit
        └──────────────────────────────────┘         i isc-test-common

                    common/run.sh læser ../kunde-a.properties
                    ────────────────────────────────────────→
```

To repoer, én kobling:

- **Koden kommer fra PwC.** Vi vedligeholder `isc-test-common` ét sted.
- **Værdierne kommer fra kunden.** De ligger i `kunde-a.properties` og røres aldrig
  af en opdatering af common.
- Common **kender ikke kundens navn**. Scriptet leder efter en `.properties`-fil i
  det repo det er submodule i. Ny kunde = nyt kunderepo med deres egen fil.

## Kom i gang

Kunden får ét link. Submodulet følger med, hvis man husker `--recurse-submodules`:

```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
cd kunde-a
common/run.sh          # macOS / Linux
common\run.bat         # Windows
```

Glemte du `--recurse-submodules`, står `common/` tom. Så kør:

```sh
git submodule update --init --recursive
```

Et submodule følger ikke automatisk med et almindeligt `git clone`.

## Hvad kunden ser

```
  Kundefil:    /…/kunde-a/kunde-a.properties
  kunde:       kunde-a
  tenant_url:  https://kunde-a.identitynow.com

  Her ville testene køre mod https://kunde-a.identitynow.com
```

## Versionering

`common/` er pinnet til én bestemt commit i `isc-test-common` — lige nu tag `v1.0.0`.
En ændring i det fælles repo rammer altså ikke kunden automatisk; pinnen flyttes
bevidst:

```sh
git -C common fetch --tags
git -C common checkout v1.1.0
git add common && git commit -m "Flyt common til v1.1.0"
```

Det er dét der gør at flere kunder kan køre hver sin version af den fælles kode.
