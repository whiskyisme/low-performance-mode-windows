@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting Administrator permission...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ================================================
echo  Low Performance Mode - All In One
echo  by whisky
echo.
echo  USDT TRC20 address:
echo  TJsEVcKs8Be8XXeJaKuGwgpxzjjybkfcmy
echo ================================================
echo 1. Enable extreme low-performance mode (custom CPU max %%)
echo 2. Enable extreme low-performance mode + NVIDIA low power (custom CPU max %%)
echo 3. Show status
echo 4. Restore normal mode
echo 0. Exit
echo.
set /p choice=Choose:

if "%choice%"=="0" exit /b
if "%choice%"=="1" call :EnableLowPerf
if "%choice%"=="2" call :EnableLowPerfNvidia
if "%choice%"=="3" call :RunPowerShell status
if "%choice%"=="4" call :RunPowerShell off

echo.
pause
exit /b

:EnableLowPerf
call :AskCpuMax || exit /b 1
call :RunPowerShell on -CpuMax %cpuMax%
exit /b

:EnableLowPerfNvidia
call :AskCpuMax || exit /b 1
call :RunPowerShell on -CpuMax %cpuMax% -NvidiaLowPower
exit /b

:AskCpuMax
set "cpuMax="
set /p "cpuMax=CPU max percent (5-100): "
if not defined cpuMax (
    echo Invalid CPU max percent. Please enter a number from 5 to 100.
    exit /b 1
)

set "LOWPERF_CPU_MAX=%cpuMax%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$v = $env:LOWPERF_CPU_MAX; $n = 0; if ($v -match '^\d+$' -and [int]::TryParse($v, [ref]$n) -and $n -ge 5 -and $n -le 100) { exit 0 }; exit 1" >nul
if errorlevel 1 (
    echo Invalid CPU max percent. Please enter a number from 5 to 100.
    exit /b 1
)

exit /b 0

:RunPowerShell
set "_ps1=%TEMP%\LowPerfMode-%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$content = Get-Content -LiteralPath '%~f0' -Raw; $marker = '# POWERSHELL_PAYLOAD_BELOW'; $start = $content.LastIndexOf($marker) + $marker.Length; $script = $content.Substring($start).TrimStart(); Set-Content -LiteralPath '%_ps1%' -Value $script -Encoding UTF8"
powershell -NoProfile -ExecutionPolicy Bypass -File "%_ps1%" %*
del "%_ps1%" >nul 2>&1
exit /b

# POWERSHELL_PAYLOAD_BELOW
param(
    [ValidateSet("on", "off", "status")]
    [string]$Mode = "on",

    [int]$CpuMax = 5,

    [switch]$NvidiaLowPower,

    [string[]]$GameExePaths = @()
)

$StateDir = Join-Path $env:LOCALAPPDATA "LowPerfMode"
$StateFile = Join-Path $StateDir "state.json"

$SUB_PROCESSOR = "54533251-82be-4824-96c1-47b60b740d00"
$PROCTHROTTLEMIN = "893dee8e-2bef-41e0-89c6-b55d0929964c"
$PROCTHROTTLEMAX = "bc5038f7-23e0-4960-96da-33abaf5935ec"
$PERFBOOSTMODE = "be337238-0d82-4146-a960-4f3749d470c7"
$PERFEPP = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"
$CPMINCORES = "0cc5b647-c1df-4637-891a-dec35c318583"
$CPMAXCORES = "ea062031-0e34-4ff1-9b6d-eb1059334028"
$SYSCOOLPOL = "94d3a615-a899-4ac5-ae2b-e4d8f634367f"
$GpuPrefKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"

function Set-PowerValueQuiet {
    param(
        [string]$SchemeGuid,
        [string]$SubgroupGuid,
        [string]$SettingGuid,
        [int]$Value
    )

    powercfg /setacvalueindex $SchemeGuid $SubgroupGuid $SettingGuid $Value 2>$null | Out-Null
    $acOk = ($LASTEXITCODE -eq 0)
    powercfg /setdcvalueindex $SchemeGuid $SubgroupGuid $SettingGuid $Value 2>$null | Out-Null
    $dcOk = ($LASTEXITCODE -eq 0)

    return ($acOk -or $dcOk)
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-AppliedSetting {
    param(
        [System.Collections.ArrayList]$AppliedSettings,
        [string]$Name,
        [bool]$Applied
    )

    if ($Applied) {
        [void]$AppliedSettings.Add($Name)
    }
}

function Get-ActiveSchemeGuid {
    $line = powercfg /getactivescheme
    if ($line -match "([a-fA-F0-9-]{36})") {
        return $matches[1]
    }

    throw "Unable to get the active power scheme."
}

function Enable-LowPerf {
    if (!(Test-IsAdministrator)) {
        throw "Please run this script as Administrator."
    }

    if ($CpuMax -lt 5) { $CpuMax = 5 }
    if ($CpuMax -gt 100) { $CpuMax = 100 }

    if (!(Test-Path $StateDir)) {
        New-Item -ItemType Directory -Path $StateDir | Out-Null
    }

    $state = [ordered]@{
        previousScheme = $null
        lowScheme = $null
        cpuMax = $CpuMax
        gpuPrefs = @()
        nvidiaApplied = $false
        nvidiaOldPowerLimit = $null
        nvidiaNewPowerLimit = $null
        appliedSettings = @()
        time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $appliedSettings = [System.Collections.ArrayList]::new()

    $previous = Get-ActiveSchemeGuid
    $dup = powercfg /duplicatescheme SCHEME_BALANCED

    if ($dup -match "([a-fA-F0-9-]{36})") {
        $lowGuid = $matches[1]
    } else {
        throw "Failed to create the low-performance power scheme."
    }

    powercfg /changename $lowGuid "Extreme Low Performance Mode" "Temporary ultra-low-power power scheme" | Out-Null
    Add-AppliedSetting $appliedSettings "CPU minimum performance 0%" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $PROCTHROTTLEMIN 0)
    Add-AppliedSetting $appliedSettings "CPU maximum performance $CpuMax%" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $PROCTHROTTLEMAX $CpuMax)
    Add-AppliedSetting $appliedSettings "CPU boost disabled" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $PERFBOOSTMODE 0)
    Add-AppliedSetting $appliedSettings "Energy preference: maximum power saving" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $PERFEPP 100)
    Add-AppliedSetting $appliedSettings "Core parking minimum 0%" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $CPMINCORES 0)
    Add-AppliedSetting $appliedSettings "Core parking maximum 10%" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $CPMAXCORES 10)
    Add-AppliedSetting $appliedSettings "Passive cooling policy" (Set-PowerValueQuiet $lowGuid $SUB_PROCESSOR $SYSCOOLPOL 0)
    powercfg /setactive $lowGuid | Out-Null

    $state.previousScheme = $previous
    $state.lowScheme = $lowGuid

    if ($GameExePaths.Count -gt 0) {
        if (!(Test-Path $GpuPrefKey)) {
            New-Item -Path $GpuPrefKey -Force | Out-Null
        }

        foreach ($path in $GameExePaths) {
            $fullPath = [System.IO.Path]::GetFullPath($path)
            $oldValue = $null
            $hadOldValue = $false

            $props = Get-ItemProperty -Path $GpuPrefKey -ErrorAction SilentlyContinue
            if ($props -and $props.PSObject.Properties[$fullPath]) {
                $oldValue = $props.PSObject.Properties[$fullPath].Value
                $hadOldValue = $true
            }

            New-ItemProperty -Path $GpuPrefKey -Name $fullPath -Value "GpuPreference=1;" -PropertyType String -Force | Out-Null

            $state.gpuPrefs += [ordered]@{
                path = $fullPath
                hadOldValue = $hadOldValue
                oldValue = $oldValue
            }
        }
    }

    if ($NvidiaLowPower) {
        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue

        if ($nvidiaSmi) {
            try {
                $query = & nvidia-smi --query-gpu=power.limit,power.min_limit --format=csv,noheader,nounits 2>$null
                $firstLine = ($query | Select-Object -First 1)

                if ($firstLine -match "^\s*([\d\.]+)\s*,\s*([\d\.]+)") {
                    $currentLimit = [double]$matches[1]
                    $minLimit = [double]$matches[2]
                    $targetLimit = [math]::Round($minLimit + 5)

                    if ($targetLimit -lt $currentLimit) {
                        & nvidia-smi -pl $targetLimit | Out-Null

                        $state.nvidiaApplied = $true
                        $state.nvidiaOldPowerLimit = $currentLimit
                        $state.nvidiaNewPowerLimit = $targetLimit
                        [void]$appliedSettings.Add("NVIDIA power limit $targetLimit W")
                    }
                }
            } catch {
                Write-Host "NVIDIA low-power change failed. The GPU or driver may not support it." -ForegroundColor Yellow
            }
        } else {
            Write-Host "nvidia-smi was not found. NVIDIA low-power change skipped." -ForegroundColor Yellow
        }
    }

    $state.appliedSettings = @($appliedSettings)
    $state | ConvertTo-Json -Depth 5 | Set-Content $StateFile -Encoding UTF8

    Write-Host "Extreme low-performance mode enabled." -ForegroundColor Yellow
    Write-Host "CPU maximum performance: $CpuMax%"
    if ($state.appliedSettings.Count -gt 0) {
        Write-Host "Applied compatible settings:"
        foreach ($setting in $state.appliedSettings) {
            Write-Host " - $setting"
        }
    }
    if ($state.nvidiaApplied) {
        Write-Host "NVIDIA power limit: $($state.nvidiaNewPowerLimit)W"
    }
    Write-Host "Restore from menu option 4." -ForegroundColor Green
}

function Disable-LowPerf {
    if (!(Test-IsAdministrator)) {
        throw "Please run this script as Administrator."
    }

    if (!(Test-Path $StateFile)) {
        Write-Host "No low-performance state file was found. Switching to Balanced mode." -ForegroundColor Yellow
        powercfg /setactive SCHEME_BALANCED | Out-Null
        return
    }

    $state = Get-Content $StateFile -Raw | ConvertFrom-Json

    if ($state.previousScheme) {
        powercfg /setactive $state.previousScheme | Out-Null
    } else {
        powercfg /setactive SCHEME_BALANCED | Out-Null
    }

    if ($state.lowScheme) {
        powercfg /delete $state.lowScheme 2>$null
    }

    if ($state.gpuPrefs) {
        foreach ($item in $state.gpuPrefs) {
            if ($item.hadOldValue -eq $true) {
                New-ItemProperty -Path $GpuPrefKey -Name $item.path -Value $item.oldValue -PropertyType String -Force | Out-Null
            } else {
                Remove-ItemProperty -Path $GpuPrefKey -Name $item.path -ErrorAction SilentlyContinue
            }
        }
    }

    if ($state.nvidiaApplied -eq $true -and $state.nvidiaOldPowerLimit) {
        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvidiaSmi) {
            try {
                & nvidia-smi -pl $state.nvidiaOldPowerLimit | Out-Null
            } catch {
                Write-Host "NVIDIA power restore failed. Restart Windows or restore defaults in NVIDIA Control Panel." -ForegroundColor Yellow
            }
        }
    }

    Remove-Item $StateFile -Force

    Write-Host "Normal mode restored." -ForegroundColor Green
}

function Show-Status {
    Write-Host "Active power scheme: $(Get-ActiveSchemeGuid)"

    if (Test-Path $StateFile) {
        $state = Get-Content $StateFile -Raw | ConvertFrom-Json
        Write-Host "Low-performance state file exists."
        Write-Host "CPU limit: $($state.cpuMax)%"
        if ($state.appliedSettings) {
            Write-Host "Applied compatible settings:"
            foreach ($setting in $state.appliedSettings) {
                Write-Host " - $setting"
            }
        }
        if ($state.nvidiaApplied -eq $true) {
            Write-Host "NVIDIA power limit: $($state.nvidiaNewPowerLimit)W"
        }
    } else {
        Write-Host "No low-performance state file detected."
    }
}

switch ($Mode) {
    "on" { Enable-LowPerf }
    "off" { Disable-LowPerf }
    "status" { Show-Status }
}
