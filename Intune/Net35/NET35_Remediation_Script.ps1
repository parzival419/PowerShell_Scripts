# NET35_Remediation_Script.ps1
# Enables the .NET Framework 3.5 (NetFx3) Windows feature.
# Runs after detection script returns exit 1.
#
# Exit 0 = remediation successful
# Exit 1 = remediation failed

try {
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
    Write-Output "Enable-WindowsOptionalFeature executed successfully."
}
catch {
    Write-Output "ERROR: Failed to enable .NET Framework 3.5. $($_.Exception.Message)"
    exit 1
}

$feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue

if ($null -eq $feature) {
    Write-Output "ERROR: Unable to verify NetFx3 feature state after remediation."
    exit 1
}

if ($feature.State -eq "Enabled") {
    Write-Output "Remediation complete: .NET Framework 3.5 is enabled."
    exit 0
}

Write-Output "Remediation failed: .NET Framework 3.5 is still not enabled (State: $($feature.State))."
exit 1
