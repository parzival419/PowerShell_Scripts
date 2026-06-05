# WinTrust_Remediation_Script.ps1
# Sets EnableCertPaddingCheck to 1 in both 32-bit and 64-bit WinTrust
# registry paths. Runs after detection script returns exit 1.
#
# Exit 0 = remediation successful
# Exit 1 = remediation failed

$registryPath    = "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config"
$registryPath32  = "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
$keyName         = "EnableCertPaddingCheck"
$desiredValue    = "1"

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$KeyName,
        [string]$Value
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Output "CREATED: $Path"
        }

        New-ItemProperty -Path $Path -Name $KeyName -Value $Value -PropertyType String -Force | Out-Null
        Write-Output "SET: $Path\$KeyName = $Value"
    }
    catch {
        Write-Output "ERROR: Failed to configure $Path\$KeyName. $_"
        exit 1
    }
}

Set-RegistryValue -Path $registryPath   -KeyName $keyName -Value $desiredValue
Set-RegistryValue -Path $registryPath32 -KeyName $keyName -Value $desiredValue

Write-Output "Remediation complete: Both registry keys are configured."
exit 0
