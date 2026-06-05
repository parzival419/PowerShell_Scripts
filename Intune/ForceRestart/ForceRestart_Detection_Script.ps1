# ForceRestart_Detection_Script.ps1
# Detects whether the device uptime exceeds 1 day.
# Used with Intune remediation in user context.
#
# Exit 0 = compliant, uptime is under 1 day
# Exit 1 = non-compliant, remediation required

function Get-UptimeSpan {
    try {
        $os  = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $raw = $os.LastBootUpTime

        if ($raw -is [DateTime]) {
            $lastBoot = $raw
        } elseif ($raw -is [string] -and $raw.Length -ge 8) {
            $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime($raw)
        } else {
            throw "Unexpected LastBootUpTime type: $($raw.GetType().FullName)"
        }

        return (Get-Date) - $lastBoot
    }
    catch {
        try {
            $perf    = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System -ErrorAction Stop
            $seconds = [double]$perf.SystemUpTime

            if ($seconds -gt 0) {
                return [TimeSpan]::FromSeconds($seconds)
            }

            throw "PerfOS SystemUpTime returned invalid value: $seconds"
        }
        catch {
            return $null
        }
    }
}

try {
    $uptime = Get-UptimeSpan

    if (-not $uptime) {
        Write-Output "Detection failed: Unable to determine device uptime."
        exit 1
    }

    if ($uptime.TotalDays -ge 1) {
        Write-Output ("Non-compliant: Device uptime is {0:dd\.hh\:mm} (>= 1 day). A reboot is required." -f $uptime)
        exit 1
    }

    Write-Output ("Compliant: Device uptime is {0:00}h {1:00}m (< 1 day)." -f [int]$uptime.TotalHours, $uptime.Minutes)
    exit 0
}
catch {
    Write-Output "Detection failed: $($_.Exception.Message)"
    exit 1
}
