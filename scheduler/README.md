# Scheduler

**Her ligger ingen kørende kode — kun eksempler.** Filerne her viser hvordan
scheduleren sættes op; de gør ikke noget i sig selv.

## Scheduleren er det der driver hele flowet

Der er ingen server, ingen kø og ingen orkestrering i dette framework. Der er en
scheduler der kalder ét script:

```
cron / Task Scheduler   →   wrapper.sh <miljø>   →   common/runner/index.js
                                                     ↓
                                          results/<miljø>/<dato>.json
                                                     ↓
                                          POST → PwC resultat-API
```

Alt andet i repoet er noget wrapperen bruger. Fjerner man scheduleren, sker der ikke
noget om natten — så det er dét led der skal overvåges.

## Den ligger på kundens vært

Ikke hos PwC. Det er et bevidst valg med konsekvenser der er værd at nævne på mødet:

- Testene kører **inde fra kundens netværk**, så de rammer ISC på samme måde som
  kundens egne brugere gør.
- Credentials forlader aldrig kundens miljø — de ligger i `secrets/` på deres vært.
- Til gengæld er det **kundens vært vi er afhængige af**. Er den nede, kører der
  ingen test, og det opdager vi først når rapporten udebliver. Overvågning af at
  rapporten *ankommer* er ikke bygget endnu — se de åbne spørgsmål i `../README.md`.

## Filer

| Fil | Hvad |
|---|---|
| `cron.txt` | Eksempel-crontab til Linux/macOS-værter. |
| `windows-task.md` | Opsætning af Scheduled Task med `schtasks`. |
