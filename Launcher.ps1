# Kornyezet beallitasa
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Állapotkövetés és Naplózás
$RegPath = "HKLM:\SOFTWARE\HardwareConflictResolver"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

function Get-StepState { param($StepName) return (Get-ItemProperty -Path $RegPath -Name $StepName -ErrorAction SilentlyContinue).$StepName }
function Set-StepState { param($StepName, $Value) New-ItemProperty -Path $RegPath -Name $StepName -Value $Value -PropertyType String -Force | Out-Null }

$LogPath = "C:\Temp\HardwareConflict_LOG.txt"
if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null }
function Write-Log { param($Msg) $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "[$t] $Msg" | Tee-Object -FilePath $LogPath -Append }

# Konfiguráció betöltése
$Config = Get-Content "$PSScriptRoot\data\GodDriverConf.json" | ConvertFrom-Json
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

try {
    # 0. Lépés: Rendszerállapot mentése
    if ((Get-StepState "InitialBackup") -ne "Done") {
        Write-Log "Riport es mentesi pont keszitese..."
        Get-PnpDevice | Select-Object FriendlyName, InstanceId, Status | Export-Csv -Path "C:\Temp\Hardware_Report.csv" -NoTypeInformation
        & "$PSScriptRoot\Scripts\Enable-RestorePoint.ps1"
        Set-StepState "InitialBackup" "Done"
    }

# --- 1. DRIVER LETOLTES (Google Drive megerosites kerulessel) ---
foreach ($Driver in $TargetDrivers) {
    $DriverPath = "$PSScriptRoot\Drivers\$OSArch\$($Driver.FileName)"
    if (!(Test-Path $DriverPath)) {
        New-Item -ItemType Directory -Path (Split-Path $DriverPath) -Force | Out-Null
        Write-Log "Letoltes inditva (GDrive bypass): $($Driver.FileName)"
        
        $FileId = ($Driver.Url -split "id=")[1]
        $Url = "https://google.com"
        
        # 1. kor: Megerosito kod lekerese
        $Response = Invoke-WebRequest -Uri $Url -SessionVariable "Session" -ErrorAction SilentlyContinue
        $Token = ($Response.Links | Where-Object { $_.href -like "*confirm=*" }).href | ForEach-Object { ($_ -split "confirm=")[1].Split("&")[0] }
        
        # 2. kor: Tenyleges letoltes a tokennel
        $DownloadUrl = if ($Token) { "$Url&confirm=$Token" } else { $Url }
        
        try {
            Invoke-WebRequest -Uri $DownloadUrl -WebSession $Session -OutFile $DriverPath -TimeoutSec 600
            Unblock-File $DriverPath
            Write-Log "SIKER: $($Driver.FileName) letoltve."
        } catch {
            Write-Log "HIBA: Nem sikerult a letoltes! ($($_.Exception.Message))"
        }
    }
}


    # 2. Mód szerinti vezérlés
    $isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

    if ($isSafe) {
        Write-Log "Csokkentett mod detektalva. Fix folyamat inditasa..."
        & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
        
        $CheckSuccess = $true
        foreach ($D in $TargetDrivers) {
            $Status = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
            if (!$Status) { $CheckSuccess = $false }
        }

        if ($CheckSuccess) {
            Set-StepState "SafeModeFix" "Done"
            Write-Log "SafeModeFix visszaellenorizve. Kerjuk inditsa ujra a gepet!"
        }
    } else {
        if ((Get-StepState "SafeModeFix") -eq "Done" -and (Get-StepState "FinalInstall") -ne "Done") {
            Write-Log "Normal mod: Telepites inditasa..."
            & "$PSScriptRoot\Fix\LenovoG500Install-Drivers.ps1"
        } elseif ((Get-StepState "FinalInstall") -eq "Done") {
            Write-Host "A rendszer mar javitva lett korabban." -ForegroundColor Green
        } else {
            Write-Log "Folyamat kezdese: Atvaltas Csokkentett modba..."
            & "$PSScriptRoot\Scripts\Set-SafeBoot-Networking.ps1"
        }
    }
}
catch {
    Write-Log "A folyamat hiba miatt leallt: $($_.Exception.Message)"
}
finally {
    if (Test-Path $LogPath) {
        Start-Process notepad.exe -ArgumentList $LogPath
    }
}
