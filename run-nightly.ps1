param(
  [string[]]$Environments = @('sandbox', 'preprod', 'prod')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$overallExit = 0

foreach ($envName in $Environments) {
  $logFile = Join-Path $logDir "$timestamp-$envName.log"
  Write-Host "=== Koerer '$envName', log: $logFile ==="

  & cmd.exe /c "`"$root\run.bat`" $envName" > $logFile 2>&1
  $exit = $LASTEXITCODE

  if ($exit -ne 0) {
    Write-Host "[FEJL] '$envName' fejlede (exit $exit) - se $logFile"
    $overallExit = 1
  } else {
    Write-Host "'$envName' bestod."
  }
}

exit $overallExit
