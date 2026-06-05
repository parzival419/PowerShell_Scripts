# WinTrust_Detection_Script.ps1
# Detects whether EnableCertPaddingCheck is correctly configured in both
# 32-bit and 64-bit WinTrust registry paths. Used with Intune remediation.
#
# Exit 0 = compliant, no remediation needed
# Exit 1 = non-compliant, remediation required

$registryPath    = "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config"
$registryPath32  = "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
$keyName         = "EnableCertPaddingCheck"
$desiredValue    = "1"

function Check-RegistryValue {
    param (
        [string]$Path,
        [string]$KeyName,
        [string]$ExpectedValue
    )

    if (-not (Test-Path $Path)) {
        Write-Output "NOT FOUND: $Path does not exist."
        return $false
    }

    $current = (Get-ItemProperty -Path $Path -Name $KeyName -ErrorAction SilentlyContinue).$KeyName

    if ($current -eq $ExpectedValue) {
        Write-Output "OK: $Path\$KeyName = $current"
        return $true
    }

    Write-Output "MISMATCH: $Path\$KeyName = '$current' (expected '$ExpectedValue')"
    return $false
}

$result64 = Check-RegistryValue -Path $registryPath   -KeyName $keyName -ExpectedValue $desiredValue
$result32 = Check-RegistryValue -Path $registryPath32 -KeyName $keyName -ExpectedValue $desiredValue

if ($result64 -and $result32) {
    Write-Output "Compliant: Both registry keys are correctly configured."
    exit 0
}

Write-Output "Non-compliant: One or both registry keys require remediation."
exit 1
