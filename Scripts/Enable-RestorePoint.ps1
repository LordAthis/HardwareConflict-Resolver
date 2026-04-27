# Rendszervedelem aktivalasa es visszaallitasi pont letrehozasa
$Date = Get-Date -Format "yyyyMMdd_HHmm"
$RPName = "NonGodDriver_$Date"

Write-Host "Rendszervedelem ellenorzese..." -ForegroundColor Cyan

# C: meghajto vedelmenek bekapcsolasa (ha le lenne tiltva)
Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue

# Maximalis tarterulet beallitasa 5%-ra (hogy biztosan legyen hely)
vssadmin resize shadowstorage /for=c: /on=c: /maxsize=5% | Out-Null

Write-Host "Visszaallitasi pont letrehozasa: $RPName" -ForegroundColor Yellow
Checkpoint-Computer -Description $RPName -RestorePointType MODIFY_SETTINGS -ErrorAction Stop

if ($?) {
    Write-Host "Sikeres mentesi pont!" -ForegroundColor Green
} else {
    Write-Host "HIBA: Nem sikerult mentesi pontot letrehozni!" -ForegroundColor Red
}
