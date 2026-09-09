# Hele historien på ~2 minutter.  Kør:  .\demo.ps1
#
# Efterlader repoet på main, som det stod da demoen begyndte.

Set-Location $PSScriptRoot

function Overskrift($tekst) {
  Write-Host ""
  Write-Host "==================================================================="
  Write-Host "  $tekst"
  Write-Host "==================================================================="
}

# Venter kun når nogen sidder og kigger.
function Pause-Demo {
  if ($Host.UI.RawUI) { Read-Host "`n  [Enter for at fortsaette]" | Out-Null }
}

Overskrift "TRIN 1 - Git-strukturen"
Write-Host "  Branch:            $(git branch --show-current)"
Write-Host "  Submodule common:  $(git submodule status common)"
Write-Host "  Pinnet version:    $(git -C common describe --tags)"
Write-Host ""
Write-Host "  Kundens eget repo indeholder config og kundespecifikke tests."
Write-Host "  Runner og basale tests kommer fra PwC's faelles repo via submodulet."
Pause-Demo

Overskrift "TRIN 2 - Prod koerer groent (ISC 2026.09, common v1.0.0)"
.\wrapper.ps1 prod
Write-Host "  Exit code: $LASTEXITCODE"
Pause-Demo

Overskrift "TRIN 3 - Samme testversion mod sandbox, hvor ISC ER opdateret"
Write-Host "  SailPoint har opdateret sandbox til 2026.10 nogle dage foer prod."
Write-Host ""
.\wrapper.ps1 sandbox
Write-Host "  Exit code: $LASTEXITCODE  <- det er meningen. Det er alarmen kunden faar."
Pause-Demo

Overskrift "TRIN 4 - Pin sandbox til en ny version af de faelles tests"
git checkout --quiet sandbox
git submodule update --init --recursive --quiet
Write-Host "  Branch:            $(git branch --show-current)"
Write-Host "  Submodule common:  $(git submodule status common)"
Write-Host "  Pinnet version:    $(git -C common describe --tags)   <- ny version"
Write-Host ""
Write-Host "  Prod ligger uroert paa main og koerer stadig v1.0.0."
Pause-Demo

Overskrift "TRIN 5 - Sandbox er groen igen"
.\wrapper.ps1 sandbox
Write-Host "  Exit code: $LASTEXITCODE"
Pause-Demo

Overskrift "TRIN 6 - Rapporten"
Get-Content "results/sandbox/$(Get-Date -Format 'yyyy-MM-dd').json"
Pause-Demo

Overskrift "TRIN 7 - Saadan driver scheduleren det"
Get-Content scheduler/cron.txt
Write-Host ""
Write-Host "  Paa Windows: se scheduler/windows-task.md."

# Efterlad repoet som det stod.
git checkout --quiet main
git submodule update --init --recursive --quiet
Write-Host ""
Write-Host "  (Repoet er sat tilbage til main / prod.)"
Write-Host ""
