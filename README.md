# kunde-a

Kundens eget repo. Det er dette link kunden får — resten følger med automatisk.

## Demo
```sh
git clone --recurse-submodules https://github.com/Luchassmed/kunde-a.git
git submodule status
.\run.bat sandbox && .\run.bat prod
git tag
```

## Versionering

`common/` er pinnet til én bestemt commit i `isc-test-common` — lige nu tag `v1.2.0`.
En ændring i det fælles repo rammer altså ikke kunden automatisk; pinnen flyttes
bevidst:

```sh
git -C common fetch --tags
git -C common checkout v1.2.0
git add common && git commit -m "Flyt common til v1.2.0"
```

Det er dét der gør at flere kunder kan køre hver sin version af den fælles kode.
