# License_Audit.ps1
# Exports a dated CSV of all licensed users and their assigned licenses.
# Uses Microsoft Graph -- replaces user_licenses.ps1 which used the
# deprecated AzureAD module.
#
# Requirements:
#   Install-Module Microsoft.Graph -Scope CurrentUser
#   Permissions: User.Read.All, Directory.Read.All

# --------------------------- Config ---------------------------
$ExportDir  = "C:\Temp"
$ExportPath = Join-Path $ExportDir "LicenseAudit-$(Get-Date -Format MM-dd-yyyy).csv"

# --------------------------- SKU Map --------------------------
# Maps license SKU part numbers to friendly display names.
# Add any missing SKUs to this table as needed.
$SkuMap = @{
    "AAD_PREMIUM_P2"            = "Azure Active Directory Premium P2"
    "EXCHANGESTANDARD"          = "Exchange Online (Plan 1)"
    "EXCHANGEENTERPRISE"        = "Exchange Online (Plan 2)"
    "MCOMEETADV"                = "Microsoft 365 Audio Conferencing"
    "O365_BUSINESS_PREMIUM"     = "Microsoft 365 Business Standard"
    "SPE_E3"                    = "Microsoft 365 E3"
    "SPE_F1"                    = "Microsoft 365 F3"
    "STANDARDPACK"              = "Office 365 E1"
    "ENTERPRISEPACK"            = "Office 365 E3"
    "DESKLESSPACK"              = "Office 365 F3"
    "WACONEDRIVESTANDARD"       = "OneDrive for Business (Plan 1)"
    "PROJECTPROFESSIONAL"       = "Project Plan 3"
    "VISIOCLIENT"               = "Visio Plan 2"
    "MICROSOFT_BUSINESS_CENTER" = "Microsoft Business Center"
    "O365_BUSINESS"             = "Microsoft 365 Apps for Business"
    "POWER_BI_STANDARD"         = "Power BI (free)"
    "POWER_BI_PRO"              = "Power BI Pro"
    "POWERAPPS_DEV"             = "Power Apps for Developer"
    "Microsoft_365_Copilot"     = "Microsoft Copilot for Microsoft 365"
    "Microsoft_Teams_Premium"   = "Microsoft Teams Premium Introductory Pricing"
}

# --------------------------- Connect --------------------------
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" -ErrorAction Stop
}
catch {
    Write-Output "ERROR: Failed to connect to Microsoft Graph. $_"
    exit 1
}

# ---------------------- Ensure export dir ---------------------
if (-not (Test-Path $ExportDir)) {
    try {
        New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
    }
    catch {
        Write-Output "ERROR: Could not create export directory $ExportDir. $_"
        exit 1
    }
}

if (Test-Path $ExportPath) {
    Remove-Item $ExportPath -Force
}

# ---------------------- Pull data -----------------------------
try {
    $AllSkus = Get-MgSubscribedSku -ErrorAction Stop
}
catch {
    Write-Output "ERROR: Failed to retrieve subscribed SKUs. $_"
    exit 1
}

try {
    $Users = Get-MgUser -All -Property "DisplayName,JobTitle,Department,UserPrincipalName,CompanyName,PhysicalDeliveryOfficeName,AssignedLicenses" -ErrorAction Stop |
        Where-Object { $_.AssignedLicenses.Count -gt 0 }
}
catch {
    Write-Output "ERROR: Failed to retrieve users. $_"
    exit 1
}

# ---------------------- Build results -------------------------
$UnknownSkus = [System.Collections.Generic.HashSet[string]]::new()

$Results = foreach ($User in $Users) {
    foreach ($License in $User.AssignedLicenses) {
        $SkuInfo      = $AllSkus | Where-Object { $_.SkuId -eq $License.SkuId }
        $SkuPart      = $SkuInfo.SkuPartNumber
        $FriendlyName = if ($SkuMap[$SkuPart]) { $SkuMap[$SkuPart] } else {
            $null = $UnknownSkus.Add($SkuPart)
            "Unknown: $SkuPart"
        }

        [PSCustomObject]@{
            Name       = $User.DisplayName
            Title      = $User.JobTitle
            Department = $User.Department
            Email      = $User.UserPrincipalName
            Sku        = $SkuPart
            License    = $FriendlyName
            Company    = $User.CompanyName
            Office     = $User.PhysicalDeliveryOfficeName
        }
    }
}

# ---------------------- Export --------------------------------
try {
    $Results | Select-Object Name, Title, Department, Email, Sku, License, Company, Office |
        Export-Csv -Path $ExportPath -NoTypeInformation -ErrorAction Stop

    Write-Output "Done. $($Results.Count) license assignments exported to $ExportPath"
}
catch {
    Write-Output "ERROR: Failed to export CSV. $_"
    exit 1
}

# ---------------------- Unknown SKU report --------------------
if ($UnknownSkus.Count -gt 0) {
    Write-Output "`nUnknown SKUs detected -- consider adding these to the SkuMap:"
    $UnknownSkus | ForEach-Object { Write-Output "  $_" }
}
