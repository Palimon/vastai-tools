#example CMD query
#vastai search offers gpu_name=RTX_PRO_6000_WS verified=false rentable=false --limit 500

# Load configuration from config.json, fall back to defaults if missing
$configPath = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{
        gpuNames = @("RTX_3090", "RTX_4090", "Q_RTX_6000", "Q_RTX_8000", "RTX_A6000", "RTX_5000Ada", "RTX_6000Ada", "RTX_5070_Ti", "RTX_5080", "RTX_5090", "RTX_PRO_6000_WS")
        hostRevenueMultiplier = 0.75
        queryLimit = 500
    }
}

$gpuNames = $config.gpuNames

function ProcessGPU {
    param ([string]$gpuName)

    $scriptName = "vast_data_{0}" -f $gpuName
    $subfolder = $scriptName

    # Create subfolder if it doesn't exist
    if (-not (Test-Path $subfolder)) { New-Item -ItemType Directory -Path $subfolder | Out-Null }

    # Define output files
    $jsonFileRented = Join-Path $subfolder ("rented_by_others.json" -f $gpuName)
    $jsonFileUnrented = Join-Path $subfolder ("unrented.json" -f $gpuName)

    # Query the Vast.ai CLI and return parsed JSON
    function Invoke-VastQuery {
        param (
            [string]$gpu,
            [string]$verified,
            [string]$rentable,
            [int]$limit
        )
        $filter = "gpu_name=$gpu verified=$verified rentable=$rentable"
        $raw = & vastai search offers $filter --limit $limit --order gpuCostPerHour --raw
        return $raw | ConvertFrom-Json
    }

    # Run commands and load data
    try {
        $dataRentedVerified    = Invoke-VastQuery -gpu $gpuName -verified "true"  -rentable "false" -limit $config.queryLimit
        $dataRentedUnverified  = Invoke-VastQuery -gpu $gpuName -verified "false" -rentable "false" -limit $config.queryLimit
        $dataUnrentedVerified  = Invoke-VastQuery -gpu $gpuName -verified "true"  -rentable "true"  -limit $config.queryLimit
        $dataUnrentedUnverified = Invoke-VastQuery -gpu $gpuName -verified "false" -rentable "true"  -limit $config.queryLimit
    } catch {
        Write-Host "Nya~! CLI error for $gpuName : $_"
        return
    }

    # Combine data
    $dataRented = $dataRentedVerified + $dataRentedUnverified
    $dataUnrented = $dataUnrentedVerified + $dataUnrentedUnverified

    # Save combined JSON
    try {
        $dataRented | ConvertTo-Json -Depth 100 | Out-File $jsonFileRented -Encoding utf8
        $dataUnrented | ConvertTo-Json -Depth 100 | Out-File $jsonFileUnrented -Encoding utf8
    } catch {
        Write-Host "Nya~! JSON save error for $gpuName : $_"
        return
    }

    # Check if data is empty
    if (-not $dataRented -and -not $dataUnrented) {
        Write-Host "Nya~! No $gpuName machines found."
        return
    }

    # Function to convert RAM to server config
    function Convert-RAMConfig {
        param ([double]$ramMB)
        $ramGB = $ramMB / 1024
        if ($ramGB -le 32) { return 32 }
        elseif ($ramGB -gt 32 -and $ramGB -le 64) { return 64 }
        elseif ($ramGB -gt 64 -and $ramGB -le 96) { return 96 }
        elseif ($ramGB -gt 96 -and $ramGB -le 128) { return 128 }
        elseif ($ramGB -gt 128 -and $ramGB -le 192) { return 192 }
        elseif ($ramGB -gt 192 -and $ramGB -le 256) { return 256 }
        elseif ($ramGB -gt 256 -and $ramGB -le 384) { return 384 }
        elseif ($ramGB -gt 384 -and $ramGB -le 512) { return 512 }
        elseif ($ramGB -gt 512 -and $ramGB -le 768) { return 768 }
        elseif ($ramGB -gt 768 -and $ramGB -le 1024) { return 1024 }
        elseif ($ramGB -gt 1024 -and $ramGB -le 1280) { return 1280 }
        elseif ($ramGB -gt 1280 -and $ramGB -le 1536) { return 1536 } # 1.5TB
        else { return [math]::Round($ramGB, 2) }
    }

    # Convert raw API objects to structured CSV-ready objects
    function Convert-MachineData {
        param ([array]$machines)
        return $machines | ForEach-Object {
            # The output PricePerHour is the per-GPU actual rental rate I see as a host after Vast.ai marketplace tax.
            $adjustedPricePerHour = [math]::Round(([double]$_.search.gpuCostPerHour / [double]$_.num_gpus) * $config.hostRevenueMultiplier, 2)
            [PSCustomObject]@{
                Verified     = $_.verified
                MachineID    = [math]::Round([double]$_.machine_id, 2)
                GPU          = $_.gpu_name
                NumGPUs      = [math]::Round([double]$_.num_gpus, 2)
                PricePerHour = $adjustedPricePerHour
                Rented       = $_.rented
                CPU          = $_.cpu_name
                CPUCores     = [math]::Round([int]$_.cpu_cores, 2)
                CPUCoresEffective = [math]::Round([double]$_.cpu_cores_effective, 2)
                RAM          = Convert-RAMConfig([double]$_.cpu_ram)
                Storage      = [math]::Round(([double]$_.disk_space / 1024), 2)
                PCIE         = [math]::Round([double]$_.pcie_bw, 2)
                DiskBW       = [math]::Round([double]$_.disk_bw, 2)
                InetDown     = [math]::Round([double]$_.inet_down, 2)
                InetUp       = [math]::Round([double]$_.inet_up, 2)
                InternetDownCostPerTB = [math]::Round([double]$_.inet_down_cost * 1024, 2)
                InternetUpCostPerTB = [math]::Round([double]$_.inet_up_cost * 1024, 2)
                StorageCost  = [math]::Round([double]$_.storage_cost, 2)
                Location     = $_.location
                MoboName     = $_.mobo_name
                VRAM_GB      = [math]::Round([double]$_.gpu_ram / 1024, 2)
            }
        }
    }

    # Prepare data for CSV
    $resultsRented = Convert-MachineData $dataRented
    $resultsUnrented = Convert-MachineData $dataUnrented

    # Get unique NumGPUs
    $allResults = $resultsRented + $resultsUnrented
    $uniqueNumGPUs = $allResults | Select-Object -Property NumGPUs -Unique | Sort-Object NumGPUs

    # Export to CSV by NumGPUs
    try {
        foreach ($num in $uniqueNumGPUs.NumGPUs) {
            $rentedFiltered = $resultsRented | Where-Object { $_.NumGPUs -eq $num }
            $unrentedFiltered = $resultsUnrented | Where-Object { $_.NumGPUs -eq $num }

            if ($rentedFiltered) {
                $csvFileRented = Join-Path $subfolder "${num}x_rented.csv"
                $rentedFiltered | Export-Csv -Path $csvFileRented -NoTypeInformation -Encoding UTF8
                Write-Host "Nya~! Rented data for ${num}x $gpuName exported to $csvFileRented"
            }

            if ($unrentedFiltered) {
                $csvFileUnrented = Join-Path $subfolder "${num}x_unrented.csv"
                $unrentedFiltered | Export-Csv -Path $csvFileUnrented -NoTypeInformation -Encoding UTF8
                Write-Host "Nya~! Unrented data for ${num}x $gpuName exported to $csvFileUnrented"
            }
        }
    } catch {
        Write-Host "Nya~! CSV error for $gpuName : $_"
    }

    # Delete JSON files
    Remove-Item -Path $jsonFileRented, $jsonFileUnrented -Force -ErrorAction SilentlyContinue
}

# Run for each GPU
foreach ($gpu in $gpuNames) {
    ProcessGPU $gpu
}