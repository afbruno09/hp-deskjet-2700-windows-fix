[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PrinterAddress,

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$EventLookbackDays = 7
)

$ErrorActionPreference = 'Continue'

Write-Host '=== Serviços ===' -ForegroundColor Cyan
Get-Service -Name Spooler, Winmgmt -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Format-Table -AutoSize

Write-Host '=== Filas instaladas ===' -ForegroundColor Cyan
try {
    Get-Printer -ErrorAction Stop |
        Select-Object Name, PrinterStatus, DriverName, PortName |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Nao foi possivel consultar as filas: $($_.Exception.Message)"
}

Write-Host '=== Trabalhos pendentes ===' -ForegroundColor Cyan
try {
    Get-Printer -ErrorAction Stop | ForEach-Object {
        $printerName = $_.Name
        Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue |
            Select-Object @{Name = 'Printer'; Expression = { $printerName } }, ID, DocumentName, JobStatus
    } | Format-Table -AutoSize
}
catch {
    Write-Warning "Nao foi possivel consultar os trabalhos: $($_.Exception.Message)"
}

$startTime = (Get-Date).AddDays(-$EventLookbackDays)

Write-Host '=== Erros recentes de impressao ===' -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-PrintService/Admin'
    Level     = 2
    StartTime = $startTime
} -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message |
    Format-List

Write-Host '=== Erros recentes do provedor de impressao/WMI ===' -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-WMI-Activity/Operational'
    Level     = 2
    StartTime = $startTime
} -MaxEvents 50 -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -match 'MSFT_Printer|MSFT_PrinterPort|StandardCimv2' } |
    Select-Object TimeCreated, Id, Message |
    Format-List

if ($PrinterAddress) {
    Write-Host "=== Conectividade com $PrinterAddress ===" -ForegroundColor Cyan
    Test-Connection -ComputerName $PrinterAddress -Count 2 -ErrorAction SilentlyContinue |
        Select-Object Address, Status, Latency |
        Format-Table -AutoSize

    $portResults = foreach ($port in 80, 443, 631, 9100) {
        $open = Test-NetConnection -ComputerName $PrinterAddress -Port $port `
            -InformationLevel Quiet -WarningAction SilentlyContinue
        [pscustomobject]@{ Port = $port; Open = $open }
    }
    $portResults | Format-Table -AutoSize
}

Write-Host ''
Write-Host 'Diagnostico concluido. Nenhuma configuracao foi alterada.' -ForegroundColor Green
