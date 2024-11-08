# Get-WSL-Resources.ps1
# Compact WSL Resource Report with error handling for empty arrays

function Write-Separator {
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Get-WSLDistributions {
    Write-Separator
    Write-Host "Fetching All Installed WSL Distributions..." -ForegroundColor Green
    Write-Separator
    wsl.exe --list --verbose | ForEach-Object {
        if ($_ -match 'NAME|STATE|VERSION') {
            Write-Host "Name                  State     Version" -ForegroundColor Yellow
        } elseif ($_ -match '\S') {
            $distInfo = $_ -split '\s{2,}'
            Write-Host ("{0,-20} {1,-10} {2,-10}" -f $distInfo[0], $distInfo[1], $distInfo[2]) -ForegroundColor Cyan
        }
    }
}

function Get-DefaultWSLDistribution {
    Write-Separator
    Write-Host "Fetching Default WSL Distribution..." -ForegroundColor Green
    Write-Separator
    $defaultDist = wsl.exe --list --default
    if ($defaultDist) {
        Write-Host "Default WSL Distribution: $defaultDist" -ForegroundColor Cyan
    } else {
        Write-Host "Default WSL Distribution: Not Set or Error" -ForegroundColor Red
    }
}

function Get-WSLNetworkConfig {
    Write-Separator
    Write-Host "Network Configuration" -ForegroundColor Green
    Write-Separator
    wsl.exe --list --verbose | ForEach-Object {
        $distName = ($_ -split '\s{2,}')[0]
        $networkInfo = wsl.exe -d $distName -- ip -4 addr show | Select-String 'inet'
        if ($networkInfo) {
            Write-Host ("{0,-20} {1}" -f $distName, $networkInfo.Matches[0].Value.Trim()) -ForegroundColor Yellow
        } else {
            Write-Host ("{0,-20} No IP assigned" -f $distName) -ForegroundColor Red
        }
    }
}

function Get-WSLResources {
    Write-Separator
    Write-Host "Resource Usage (Disk, Memory, Uptime)" -ForegroundColor Green
    Write-Separator
    wsl.exe --list --verbose | ForEach-Object {
        $distName = ($_ -split '\s{2,}')[0]
        
        # Get disk usage, set defaults if not available
        $diskInfo = wsl.exe -d $distName -- df -h / | Select-String '/' | ForEach-Object { $_.Line -split '\s+' }
        $totalDisk = if ($diskInfo.Count -ge 2) { $diskInfo[1] } else { "N/A" }
        $usedDisk = if ($diskInfo.Count -ge 3) { $diskInfo[2] } else { "N/A" }
        $freeDisk = if ($diskInfo.Count -ge 4) { $diskInfo[3] } else { "N/A" }

        # Get memory usage, set defaults if not available
        $memoryInfo = wsl.exe -d $distName -- free -h | Select-String 'Mem' | ForEach-Object { $_.Line -split '\s+' }
        $memUsed = if ($memoryInfo.Count -ge 3) { $memoryInfo[2] } else { "N/A" }

        # Get uptime, set default if not available
        $uptimeInfo = wsl.exe -d $distName -- uptime | Select-String -Pattern 'up\s+\d+:\d+' -AllMatches
        $uptime = if ($uptimeInfo.Count -gt 0) { $uptimeInfo.Matches[0].Value.Trim() } else { "N/A" }

        # Display the formatted output with default values if any part is missing
        Write-Host ("{0,-20} Disk:{1,8} Used:{2,8} Free:{3,8} MemUsed:{4,5} Uptime:{5}" -f `
            $distName, $totalDisk, $usedDisk, $freeDisk, $memUsed, $uptime) -ForegroundColor Yellow
    }
}

function Get-OverallMemoryUsage {
    Write-Separator
    Write-Host "Overall System Memory Usage" -ForegroundColor Green
    Write-Separator
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $usedMemory = (Get-Process -Name "vmmem*" | Measure-Object WorkingSet -Sum).Sum

    Write-Host ("Total: {0} GB, Used: {1} GB, Free: {2} GB" -f `
        [math]::Round($totalMemory / 1GB, 2),
        [math]::Round($usedMemory / 1GB, 2),
        [math]::Round(($totalMemory - $usedMemory) / 1GB, 2)) -ForegroundColor Cyan
}

Write-Host "`nWSL Resource Report" -ForegroundColor Magenta
Write-Separator
Get-WSLDistributions
Get-DefaultWSLDistribution
Get-WSLNetworkConfig
Get-WSLResources
Get-OverallMemoryUsage
Write-Host "WSL Resource Report Complete" -ForegroundColor Magenta
Write-Separator
