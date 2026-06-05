# ForceRestart_Remediation_Script.ps1
# Prompts the user to reboot via Windows toast notifications.
# Allows up to 2 deferrals before forcing a restart countdown.
# Runs after detection script returns exit 1.
# Requires user context in Intune.
#
# Exit 0 = remediation successful
# Exit 1 = remediation failed
#
# --------------------------- Config ---------------------------
# Update these values to match your organization before deploying.

$OrgName             = "IT Support"                          # Display name shown in toast and shutdown message
$HeroImageUri        = "https://your-storage-account.blob.core.windows.net/intune/toast-hero.png"  # Public URL to your hero image
$LocalImageRoot      = Join-Path $env:LOCALAPPDATA "ITSupport\images"
$LocalHeroImagePath  = Join-Path $LocalImageRoot "toast-hero.png"
$LocalLogoPath       = $LocalHeroImagePath

$ToastAppID          = $OrgName
$ToastHeadline       = "A reboot of your system is required!"
$ToastSubhead        = "Your system has received critical security updates that need a reboot to take effect."
$ToastPrompt         = "Run reboot now?"

$RegistryBase        = "HKCU:\Software\ITSupport\RebootPrompt"
$MaxDeferrals        = 2
$DeferralSleepSeconds = 2.5 * 60 * 60   # 2.5 hours between prompts
$ForcedRebootSeconds  = 900              # 15 minute countdown after final prompt

$ProtocolName        = "ITSupportActionReboot"
$CmdScriptDir        = Join-Path $env:LOCALAPPDATA "ITSupport\bin"
$CmdScriptPath       = Join-Path $CmdScriptDir "$ProtocolName.cmd"

# ---------------------- Helper: Uptime ------------------------
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
                return (New-TimeSpan -Seconds $seconds)
            }

            throw "PerfOS SystemUpTime returned invalid value: $seconds"
        }
        catch {
            return $null
        }
    }
}

# -------------------- Deferral State (HKCU) -------------------
function Get-DeferralState {
    if (-not (Test-Path $RegistryBase)) {
        New-Item -Path $RegistryBase -Force | Out-Null
        New-ItemProperty -Path $RegistryBase -Name "DeferralCount"   -Value 0                        -PropertyType DWord  -Force | Out-Null
        New-ItemProperty -Path $RegistryBase -Name "FirstPromptTime" -Value (Get-Date).ToString("o") -PropertyType String -Force | Out-Null
    }

    return @{
        Count           = (Get-ItemProperty -Path $RegistryBase -Name DeferralCount   -ErrorAction SilentlyContinue).DeferralCount
        FirstPromptTime = (Get-ItemProperty -Path $RegistryBase -Name FirstPromptTime -ErrorAction SilentlyContinue).FirstPromptTime
    }
}

function Set-DeferralCount([int]$count) {
    New-Item -Path $RegistryBase -Force | Out-Null
    New-ItemProperty -Path $RegistryBase -Name "DeferralCount" -Value $count -PropertyType DWord -Force | Out-Null

    if ($count -eq 0) {
        New-ItemProperty -Path $RegistryBase -Name "FirstPromptTime" -Value (Get-Date).ToString("o") -PropertyType String -Force | Out-Null
    }
}

# ------------------- Toast Prerequisites (WinRT) --------------
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

function Register-NotificationApp {
    param([string]$AppID, [string]$DisplayName)

    $path = "HKCU:\Software\Classes\AppUserModelId\$AppID"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name "DisplayName" -Value $DisplayName -PropertyType String -Force | Out-Null
}

function Ensure-HeroImage {
    try {
        if (-not (Test-Path $LocalImageRoot)) {
            New-Item -ItemType Directory -Path $LocalImageRoot -Force | Out-Null
        }
        if (-not (Test-Path $LocalHeroImagePath -PathType Leaf)) {
            Invoke-WebRequest -Uri $HeroImageUri -OutFile $LocalHeroImagePath -UseBasicParsing -ErrorAction Stop
        }
    }
    catch {
        # Best-effort; toast will render without a hero image if download fails
    }
}

function Register-ProtocolAction {
    param([string]$ActionName, [string]$CmdPath)

    $mainReg     = "HKCU:\SOFTWARE\Classes\$ActionName"
    $commandPath = "$mainReg\shell\open\command"

    if (-not (Test-Path $commandPath)) { New-Item $commandPath -Force | Out-Null }
    New-ItemProperty -Path $mainReg -Name "URL Protocol" -Value ""                    -PropertyType String -Force | Out-Null
    Set-ItemProperty -Path $mainReg -Name "(Default)"    -Value "URL:$ActionName Protocol"                 -Force | Out-Null
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $CmdPath                                  -Force | Out-Null
}

function Ensure-RebootCommandScript {
    if (-not (Test-Path $CmdScriptDir)) {
        New-Item -ItemType Directory -Path $CmdScriptDir -Force | Out-Null
    }

    $content = @"
@echo off
REM Triggered by toast Reboot Now action (user context)
shutdown /r /t 5 /c "$OrgName`: Restarting your device to complete critical updates."
"@
    Set-Content -Path $CmdScriptPath -Value $content -Force -Encoding ASCII
}

# ---------------------- Toast Notification --------------------
function Show-Toast {
    param(
        [switch]$Final,
        [int]$DeferralsLeft = 0,
        [string]$HeroPath,
        [string]$LogoPath
    )

    $heroXml = ""
    if ($HeroPath -and (Test-Path $HeroPath -PathType Leaf)) {
        $heroXml = "<image placement=`"hero`" hint-crop=`"Unspecified`" src=`"$HeroPath`" />"
    }

    $logoXml = ""
    if ($LogoPath -and (Test-Path $LogoPath -PathType Leaf)) {
        $logoXml = "<image placement=`"appLogoOverride`" hint-crop=`"circle`" src=`"$LogoPath`" />"
    }

    $protoArgs     = "{0}:" -f $ProtocolName
    $rebootAction  = "<action activationType=`"protocol`" arguments=`"$protoArgs`" content=`"Reboot Now`" />"
    $dismissAction = if ($Final) { "" } else { "<action activationType=`"system`" arguments=`"dismiss`" content=`"Dismiss`" />" }
    $statusText    = if ($Final) { "No deferrals remaining. Your device will restart shortly." } else { "You have $DeferralsLeft deferral(s) left." }

    [xml]$toastXml = @"
<toast scenario="reminder">
  <visual>
    <binding template="ToastGeneric">
      $heroXml
      $logoXml
      <text>$ToastHeadline</text>
      <text>$ToastSubhead</text>
      <text>$statusText</text>
      <group><subgroup>
        <text hint-style="body" hint-wrap="true">$ToastPrompt</text>
      </subgroup></group>
    </binding>
  </visual>
  <actions>
    $rebootAction
    $dismissAction
  </actions>
</toast>
"@

    $doc = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $doc.LoadXml($toastXml.OuterXml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ToastAppID).Show($doc)
}

function Start-ForcedReboot {
    param([int]$DelaySeconds = 900)
    shutdown /r /t $DelaySeconds /c "$OrgName`: Your device will restart to complete critical updates. Please save your work."
}

# ------------------------------ Main --------------------------
$uptime = Get-UptimeSpan

if ($uptime -and $uptime.TotalDays -lt 1) {
    Write-Output ("Remediation: Uptime {0:dd\.hh\:mm} < 1 day. No action needed." -f $uptime)
    exit 0
}

Register-NotificationApp -AppID $ToastAppID -DisplayName $OrgName
Ensure-HeroImage

$toastHero = if (Test-Path $LocalHeroImagePath -PathType Leaf) { $LocalHeroImagePath } else { "" }
$toastLogo = if (Test-Path $LocalLogoPath      -PathType Leaf) { $LocalLogoPath      } else { "" }

Ensure-RebootCommandScript
Register-ProtocolAction -ActionName $ProtocolName -CmdPath $CmdScriptPath

$state         = Get-DeferralState
$deferralCount = [int]$state.Count
$deferralsLeft = $MaxDeferrals - $deferralCount

Write-Output "Remediation: DeferralCount=$deferralCount, DeferralsLeft=$deferralsLeft"

if ($deferralCount -lt $MaxDeferrals) {
    Show-Toast -Final:$false -DeferralsLeft $deferralsLeft -HeroPath $toastHero -LogoPath $toastLogo
    Start-Sleep -Seconds $DeferralSleepSeconds
    $deferralCount++
    Set-DeferralCount -count $deferralCount
    Write-Output "Remediation: Incremented deferral count to $deferralCount."
    exit 0
}

Write-Output "Remediation: Max deferrals reached. Sending final toast and starting restart countdown."
Show-Toast -Final -DeferralsLeft 0 -HeroPath $toastHero -LogoPath $toastLogo
Start-ForcedReboot -DelaySeconds $ForcedRebootSeconds
exit 0
