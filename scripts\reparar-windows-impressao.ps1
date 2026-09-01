[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw 'Execute este script em um PowerShell aberto como administrador.'
}

if (-not $PSCmdlet.ShouldProcess('Windows', 'Executar DISM, SFC e recuperacao do repositorio WMI')) {
    return
}

$logPath = Join-Path $PSScriptRoot ("reparo-windows-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

"Inicio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" |
    Set-Content -LiteralPath $logPath -Encoding UTF8

Write-Host 'Etapa 1/3: DISM RestoreHealth. Nao feche esta janela.' -ForegroundColor Cyan
& DISM.exe /Online /Cleanup-Image /RestoreHealth 2>&1 |
    Tee-Object -FilePath $logPath -Append
$dismCode = $LASTEXITCODE

Write-Host 'Etapa 2/3: SFC Scannow.' -ForegroundColor Cyan
& sfc.exe /scannow 2>&1 |
    Tee-Object -FilePath $logPath -Append
$sfcCode = $LASTEXITCODE

Write-Host 'Etapa 3/3: WMI SalvageRepository.' -ForegroundColor Cyan
& winmgmt.exe /salvagerepository 2>&1 |
    Tee-Object -FilePath $logPath -Append
$wmiCode = $LASTEXITCODE

"Codigos finais: DISM=$dismCode; SFC=$sfcCode; WMI=$wmiCode" |
    Add-Content -LiteralPath $logPath -Encoding UTF8

Write-Host ''
Write-Host "Concluido. Relatorio: $logPath" -ForegroundColor Green
Write-Host 'Reinicie o computador antes de reinstalar a impressora.' -ForegroundColor Yellow
