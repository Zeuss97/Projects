try {
# Set variables
$SnipeItURL = "<enter_your-server_IP_here"
$ApiToken = "<enter_your_API_key_here"

# Collect hardware info
$ComputerName = $env:COMPUTERNAME
$Serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber
$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model
$Manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
$OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$CPU = (Get-WmiObject -Class Win32_Processor).Name
$RAM = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$Disk = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)
$MAC = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled }).MACAddress -join ", "
 # Get all IPv4 (try first with Get-NetIPAddress, if it fails use WMI)
    try {
        $IPs = (Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' -and $_.PrefixOrigin -ne "WellKnown" } |
            Select-Object -ExpandProperty IPAddress)
        if (-not $IPs) { throw "No IPs found" }
    } catch {
        $IPs = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -and $_.IPEnabled } | ForEach-Object { $_.IPAddress } | Where-Object { $_ -notlike '127.*' -and $_ -notlike '169.254*' })
    }
    $IPsString = $IPs -join ", "
# Prepare asset JSON
$Asset = @{
    name = $ComputerName
    serial = $Serial
    model_id = 1 # You may want to look up or create the model first
    status_id = 2 # e.g., "Deployed"
    notes = "CPU: $CPU; RAM: $RAM GB; Disk: $Disk GB; MAC: $MAC; OS: $OS; IPs: $IPsString"
}

$AssetJson = $Asset | ConvertTo-Json

# Set headers
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Accept" = "application/json"
    "Content-Type" = "application/json"
}

    # search assets by serial
    $SearchUrl = "$SnipeItURL/hardware?search=$Serial"
    $Response = Invoke-RestMethod -Uri $SearchUrl -Headers $Headers -Method Get

    # Filter by exact match (unique serial )
    $FoundAsset = $Response.rows | Where-Object { $_.serial -eq $Serial }

if ($FoundAsset) {
    # Asset exists, update ONLY the fields that are missing, NOT the serial
    $AssetId = $FoundAsset.id
    $UpdateUrl = "$SnipeItURL/hardware/$AssetId"
    # Create a new object with the serial
    $AssetPatch = @{
        name = $ComputerName
        model_id = 1
        status_id = 2
        notes = "CPU: $CPU; RAM: $RAM GB; Disk: $Disk GB; MAC: $MAC; OS: $OS; IPs: $IPsString"
    }
    $AssetPatchJson = $AssetPatch | ConvertTo-Json
    $UpdateResult = Invoke-RestMethod -Uri $UpdateUrl -Headers $Headers -Method Patch -Body $AssetPatchJson
    Write-Host "Asset updated in Snipe-IT (ID $AssetId)."
    Write-Host ($UpdateResult | ConvertTo-Json -Depth 10)
} else {
    # Asset does not exist, create a new one here (Serial goes here)
    $CreateUrl = "$SnipeItURL/hardware"
    $CreateResult = Invoke-RestMethod -Uri $CreateUrl -Headers $Headers -Method Post -Body $AssetJson
    Write-Host "Asset created in Snipe-IT."
    Write-Host ($CreateResult | ConvertTo-Json -Depth 10)
}

    
} catch {
     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response -ne $null) {
        # This works on Windows PowerShell (5.x)
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Answer from the server (PS 5.x): $responseBody" -ForegroundColor Yellow
        } catch {
            Write-Host "Couldn't read from PS 5.x, trying alternative method..." -ForegroundColor Yellow
        }
    }
    # Alternative method for PowerShell 7+
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "Answer from server (PS 7+): $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
}
Read-Host "Press ENTER to exit"