# ============================================================
# Step 0: Strict error handling
# ============================================================
$ErrorActionPreference = "Stop"

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# ============================================================
# Step 1: Connect to Microsoft Graph (reuse session if present)
# ============================================================
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All" -UseDeviceAuthentication -NoWelcome
}
if (-not (Get-MgContext)) { throw "Graph connection failed." }

# ============================================================
# Step 2: Build SKU -> friendly name map (keyed by SkuPartNumber)
# ============================================================
$SkuMap = @{
    "AAD_PREMIUM_P2"          = "Azure Active Directory Premium P2"
    "EXCHANGESTANDARD"        = "Exchange Online (Plan 1)"
    "EXCHANGEENTERPRISE"      = "Exchange Online (Plan 2)"
    "MCOMEETADV"              = "Microsoft 365 Audio Conferencing"
    "O365_BUSINESS_PREMIUM"   = "Microsoft 365 Business Standard"
    "SPE_E3"                  = "Microsoft 365 E3"
    "SPE_F1"                  = "Microsoft 365 F3"
    "STANDARDPACK"            = "Office 365 E1"
    "ENTERPRISEPACK"          = "Office 365 E3"
    "DESKLESSPACK"            = "Office 365 F3"
    "WACONEDRIVESTANDARD"     = "OneDrive for Business (Plan 1)"
    "PROJECTPROFESSIONAL"     = "Project Plan 3"
    "VISIOCLIENT"             = "Visio Plan 2"
    "Microsoft_365_Copilot"   = "Microsoft Copilot for Microsoft 365"
    "Microsoft_Teams_Premium" = "Microsoft Teams Premium Introductory Pricing"
}

# ============================================================
# Step 3: Resolve tenant SKUs -> map SkuId (GUID) to SkuPartNumber
# ============================================================
$SkuIdToPart = @{}
foreach ($Sku in Get-MgSubscribedSku -All) {
    $SkuIdToPart[$Sku.SkuId.ToString()] = $Sku.SkuPartNumber
}

# ============================================================
# Step 4: Prepare export path
# ============================================================
$Date       = Get-Date -Format "MM-dd-yyyy"
$ExportDir  = "C:\temp"
$ExportPath = "$ExportDir\AzureLicenses-$Date.csv"
if (-not (Test-Path -Path $ExportDir)) {
    New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
}

# ============================================================
# Step 5: Get licensed users (explicitly request needed props)
# ============================================================
$Props = @("DisplayName","JobTitle","Department","UserPrincipalName","OfficeLocation","AssignedLicenses")
$Users = Get-MgUser -All -Property $Props |
         Where-Object { $_.AssignedLicenses.Count -gt 0 }

$Report       = [System.Collections.Generic.List[object]]::new()
$LicenseCount = @{}

foreach ($User in $Users) {
    foreach ($License in $User.AssignedLicenses) {
        $SkuId = $License.SkuId.ToString()

        # GUID -> part number -> friendly name
        $PartNumber = $SkuIdToPart[$SkuId]
        if ($PartNumber -and $SkuMap.ContainsKey($PartNumber)) {
            $SkuName = $SkuMap[$PartNumber]
        } elseif ($PartNumber) {
            $SkuName = $PartNumber          # known to tenant but not in map
        } else {
            $SkuName = "Unknown SKU ($SkuId)"
        }

        # Count per SKU
        if ($LicenseCount.ContainsKey($SkuName)) { $LicenseCount[$SkuName]++ }
        else { $LicenseCount[$SkuName] = 1 }

        $Report.Add([PSCustomObject]@{
            Name       = $User.DisplayName
            Title      = $User.JobTitle
            Department = $User.Department
            Email      = $User.UserPrincipalName
            License    = $SkuName
            Office     = $User.OfficeLocation
        })
    }
}

# ============================================================
# Step 6: Validate, export, summarize
# ============================================================
if ($Report.Count -eq 0) { throw "No licensed users returned — check connection and scopes." }

$Report | Sort-Object Name | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Host "`nLicense report exported to $ExportPath ($($Report.Count) rows)"

Write-Host "`nLicense counts:"
$LicenseCount.GetEnumerator() | Sort-Object Name |
    Format-Table @{N="License";E={$_.Key}}, @{N="Count";E={$_.Value}} -AutoSize
