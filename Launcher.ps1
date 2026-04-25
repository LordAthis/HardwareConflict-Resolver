$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DriverDir = Join-Path $PSScriptRoot "Drivers"
$LogDir = Join-Path $PSScriptRoot "LOG"

# Mappak letrehozasa
foreach ($dir in @($DriverDir, $LogDir)) { if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force } }

# Automata letoltes, ha hianyoznak a driverek
$Drivers = @{
    "Intel_HD4000.exe" = "https://intel.com"
    "AMD_Radeon.exe"   = "https://lenovo.com"
}

foreach ($file in $Drivers.Keys) {
    $path = Join-Path $DriverDir $file
    if (!(Test-Path $path)) {
        Write-Host "[!] $file hianyzik. Letoltes folyamatban..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Drivers[$file] -OutFile $path
    }
}
