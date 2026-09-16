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
