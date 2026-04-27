$Date = Get-Date -Format "yyyyMMdd_HHmm"
$RPName = "NonGodDriver_$Date"

Write-Host "Rendszervedelem bekapcsolasa..." -ForegroundColor Cyan
Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
vssadmin resize shadowstorage /for=c: /on=c: /maxsize=5% | Out-Null

Write-Host "Visszaallitasi pont letrehozasa: $RPName" -ForegroundColor Yellow
Checkpoint-Computer -Description $RPName -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
