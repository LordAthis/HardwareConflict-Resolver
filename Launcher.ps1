$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$RegPath = "HKLM:\SOFTWARE\HardwareConflictResolver"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

function Get-StepState { param($StepName) return (Get-ItemProperty -Path $RegPath -Name $StepName -ErrorAction SilentlyContinue).$StepName }
function Set-StepState { param($StepName, $Value) New-ItemProperty -Path $RegPath -Name $StepName -Value $Value -PropertyType String -Force | Out-Null }

$LogPath = "C:\Temp\HardwareConflict_LOG.txt"
if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null }
function Write-Log { param($Msg) $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "[$t] $Msg" | Tee-Object -FilePath $LogPath -Append }

$Config = Get-Content "$PSScriptRoot\data\GodDriverConf.json" | ConvertFrom-Json
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

# 0. Lépés: Riport és Visszaállítási pont (Kényszerítve)
if ((Get-StepState "InitialBackup") -ne "Done") {
    Write-Log "Riport keszitese és visszaallitasi pont kenyszeritese..."
    Get-PnpDevice | Select-Object FriendlyName, InstanceId, Status | Export-Csv -Path "C:\Temp\Hardware_Report.csv" -NoTypeInformation
    & "$PSScriptRoot\Scripts\Enable-RestorePoint.ps1"
    Set-StepState "InitialBackup" "Done"
}

# 1. Driver letöltés (Ha hiányzik)
foreach ($Driver in $TargetDrivers) {
    $DriverPath = "$PSScriptRoot\Drivers\$OSArch\$($Driver.FileName)"
    if (!(Test-Path $DriverPath)) {
        New-Item -ItemType Directory -Path (Split-Path $DriverPath) -Force | Out-Null
        Write-Log "Letoltes inditva: $($Driver.FileName)"
        Invoke-WebRequest -Uri $Driver.Url -OutFile $DriverPath
        Unblock-File $DriverPath
    }
}

# 2. Mód szerinti futtatás
$isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

if ($isSafe) {
    Write-Log "Csokkentett mod detektalva. Fix inditasa..."
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    
    # Dinamikus ellenőrzés a JSON alapján
    $CheckSuccess = $true
    foreach ($D in $TargetDrivers) {
        $Status = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
        if (!$Status) { $CheckSuccess = $false }
    }

    if ($CheckSuccess) {
        Set-StepState "SafeModeFix" "Done"
        Write-Log "SafeModeFix SIKERES. Kerjuk inditsa ujra a gepet normal modban."
    } else {
        Write-Log "HIBA: A Fix lefutott, de a driverek nem felelnek meg a JSON-nak!"
    }
} else {
    if ((Get-StepState "SafeModeFix") -eq "Done" -and (Get-StepState "FinalInstall") -ne "Done") {
        Write-Log "Normal mod: Telepites inditasa..."
        & "$PSScriptRoot\Fix\LenovoG500Install-Drivers.ps1"
    } elseif ((Get-StepState "FinalInstall") -eq "Done") {
        Write-Host "A rendszer mar optimalis allapotban van!" -ForegroundColor Green
    } else {
        Write-Log "Folyamat inditasa: Csokkentett modba valtas..."
        & "$PSScriptRoot\Scripts\Set-SafeBoot-Networking.ps1"
    }
}
