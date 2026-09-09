# Scheduled Task på Windows

Det samme som `cron.txt` beskriver, bare på en Windows-vært. Én opgave pr. miljø,
med hver sin mappe — se forklaringen i `cron.txt` om hvorfor der er to checkouts.

## Opret med schtasks

Sandbox, hver nat kl. 01:00:

```bat
schtasks /create ^
  /tn "PwC ISC autotest - kunde-a sandbox" ^
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\pwc\kunde-a-sandbox\wrapper.ps1 sandbox" ^
  /sc daily /st 01:00 ^
  /ru "DOMÆNE\svc-pwc-autotest" /rp
```

Prod, hver nat kl. 02:00:

```bat
schtasks /create ^
  /tn "PwC ISC autotest - kunde-a prod" ^
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\pwc\kunde-a-prod\wrapper.ps1 prod" ^
  /sc daily /st 02:00 ^
  /ru "DOMÆNE\svc-pwc-autotest" /rp
```

## Praktiske detaljer

- **Kør som servicekonto**, ikke som en navngiven medarbejder. Opgaven skal overleve
  at nogen holder op.
- `/ru` + `/rp` beder om kodeordet. Sæt desuden opgaven til *"Run whether user is
  logged on or not"* i Task Scheduler-GUI'en, ellers kører den kun ved login.
- **Exit code** fra `wrapper.ps1` bliver til opgavens "Last Run Result". Kundens
  eget overvågningssystem kan læse den — 0 = alt grønt, 1 = en test fejlede,
  2 = noget kunne ikke gennemføres.
- Kontrollér manuelt første gang: `schtasks /run /tn "PwC ISC autotest - kunde-a sandbox"`
- Slet igen: `schtasks /delete /tn "PwC ISC autotest - kunde-a sandbox" /f`
