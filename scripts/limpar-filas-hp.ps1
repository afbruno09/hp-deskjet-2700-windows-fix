[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PrinterPattern,

    [Parameter()]
    [switch]$ClearAllPrintJobs
)

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw 'Execute este script em um PowerShell aberto como administrador.'
}

$printerRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers'
$backupPath = Join-Path $PSScriptRoot ("backup-impressoras-{0}.reg" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

& reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Control\Print\Printers' $backupPath /y | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'O backup do Registro falhou. Nenhuma fila foi removida.'
}

Write-Host "Backup criado em: $backupPath" -ForegroundColor Green

$matchingPrinters = Get-Printer -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*$PrinterPattern*" }

foreach ($printer in $matchingPrinters) {
    if ($PSCmdlet.ShouldProcess($printer.Name, 'Remover fila de impressao')) {
        Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue |
            Remove-PrintJob -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Printer -Name $printer.Name -Confirm:$false
    }
}

$registryMatches = Get-ChildItem -LiteralPath $printerRoot -ErrorAction Stop |
    Where-Object { $_.PSChildName -like "*$PrinterPattern*" }

if ($registryMatches) {
    Stop-Service -Name Spooler -Force
    try {
        foreach ($key in $registryMatches) {
            if ($PSCmdlet.ShouldProcess($key.PSChildName, 'Remover registro residual da fila')) {
                Remove-Item -LiteralPath $key.PSPath -Recurse -Force
            }
        }

        if ($ClearAllPrintJobs -and $PSCmdlet.ShouldProcess('Todas as filas', 'Excluir trabalhos presos')) {
            Get-ChildItem -LiteralPath "$env:windir\System32\spool\PRINTERS" -Force `
                -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    finally {
        Start-Service -Name Spooler
    }
}

Write-Host 'Limpeza concluida. Reinicie o computador antes de adicionar a impressora novamente.' -ForegroundColor Green
