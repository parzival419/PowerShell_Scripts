
# Connect to Azure AD
Connect-AzureAD

# Define SKU to friendly name mapping
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
    "MICROSOFT_BUSINESS_CENTER"= "Microsoft Business Center"
    "O365_BUSINESS"             = "Microsoft 365 Apps for Business"
    "POWER_BI_STANDARD"         = "Power BI (free)"
    "POWER_BI_PRO"              = "Power BI Pro"
    "POWERAPPS_DEV"             = "Power Apps for Developer"
    "Microsoft_365_Copilot"     = "Microsoft Copilot for Microsoft 365"
    "Microsoft_Teams_Premium"   = "Microsoft Teams Premium Introductory Pricing"
}

# Get today's date
$Date = Get-Date -Format MM-dd-yyyy

# Get all licensed users
$Users = Get-AzureADUser -All $true | Where-Object { $_.AssignedLicenses.Count -gt 0 }

# Prepare export path
$ExportPath = "C:\Temp\AzureLicenseInventory-$Date.csv"

foreach ($User in $Users) {
    $Licenses = $User.AssignedLicenses
    $Office = Get-AzureADUser -ObjectId $User.ObjectId
    $Company = if ($Office) { $Office.CompanyName } else { "N/A" }

    foreach ($License in $Licenses) {
        $SkuId = $License.SkuId
        $SkuInfo = Get-AzureADSubscribedSku | Where-Object { $_.SkuId -eq $SkuId }
        $SkuPart = $SkuInfo.SkuPartNumber
        $FriendlyName = $SkuMap[$SkuPart]
        if (-not $FriendlyName) { $FriendlyName = "Unknown SKU" }

        New-Object -TypeName PSObject -Property @{
            'Name'       = $User.DisplayName
            'Title'      = $User.JobTitle
            'Department' = $User.Department
            'Email'      = $User.UserPrincipalName
            'Sku'        = $SkuPart
            'License'    = $FriendlyName
            'Company'    = $Company
            'Office'     = $User.PhysicalDeliveryOfficeName
        } | Select-Object 'Name','Title','Department','Email','Sku','License','Company','Office' |
            Export-Csv -Path $ExportPath -NoTypeInformation -Append
    }
}
