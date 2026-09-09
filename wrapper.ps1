# Det Windows Task Scheduler kalder hver nat:  .\wrapper.ps1 sandbox|prod
#
# Bemærk: git-fejl stopper ikke kørslen med vilje. Hvis kundens vært ikke kan nå
# GitHub, skal natten stadig testes på den kode der allerede ligger lokalt.
# En fejlet opdatering må aldrig betyde at der ingen test blev kørt.

param([Parameter(Mandatory = $true)][ValidateSet("sandbox", "prod")][string]$Miljo)

$Rod = $PSScriptRoot
Set-Location $Rod
$Dato = Get-Date -Format "yyyy-MM-dd"
$Rapport = "results/$Miljo/$($Dato).json"

# 1-3. Hent nyeste kode. Fejler det, logges en advarsel og vi kører videre.
Write-Host "-> Opdaterer kode ..."
git pull --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "  ADVARSEL: git pull fejlede - koerer videre paa lokal kode." }
git submodule update --init --recursive --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "  ADVARSEL: submodule update fejlede - koerer videre paa lokal version af common." }

# 4-6. Kør testene og skriv rapporten.
node common/runner/index.js --config "config/$($Miljo).json" --kunde-rod $Rod --out $Rapport
$Kode = $LASTEXITCODE

# 7. Aflevering til PwC er ikke bygget endnu — her ville rapporten blive sendt.
Write-Host "  POST -> PwC resultat-API (simuleret): $Rapport"

# 8. Exit code følger resultatet, så scheduleren kan se om natten gik godt.
exit $Kode
