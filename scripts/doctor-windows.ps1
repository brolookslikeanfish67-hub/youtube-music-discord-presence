#Requires -Version 5.1
<#
  Diagnoses the YouTube Music Discord Presence installation for the
  current Windows user. Works on both Windows 10 and Windows 11.
#>
[CmdletBinding()]
param()

$HostName = "dev.ayaka.youtube_music_discord_presence"
$ExtensionId = "klebilgcaopidgkbffhnffgjljegimno"
$InstallRoot = Join-Path $env:LOCALAPPDATA "youtube-music-discord-presence"
$AppConfigRoot = Join-Path $env:APPDATA "youtube-music-discord-presence"
$failures = 0

function Check-File([string]$Path, [string]$Label) {
    if (Test-Path $Path) {
        Write-Host "[ok] $Label`: $Path"
    } else {
        Write-Host "[missing] $Label`: $Path"
        $script:failures++
    }
}

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeVersion = (& node --version)
    Write-Host "[ok] Node: $nodeVersion ($($node.Source))"
} else {
    Write-Host "[missing] Node.js"
    $failures++
}

$braveBetaExe = @(
    Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser-Beta\Application\brave.exe",
    Join-Path ${env:ProgramFiles} "BraveSoftware\Brave-Browser-Beta\Application\brave.exe",
    Join-Path ${env:ProgramFiles(x86)} "BraveSoftware\Brave-Browser-Beta\Application\brave.exe"
) | Where-Object { Test-Path $_ }
if ($braveBetaExe) {
    Write-Host "[ok] Brave Beta: $($braveBetaExe[0])"
} else {
    Write-Host "[missing] Brave Browser Beta"
    $failures++
}

$discordExe = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Discord") -Filter "Discord.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($discordExe) {
    Write-Host "[ok] Discord: $($discordExe.FullName)"
} else {
    Write-Host "[missing] Discord"
    $failures++
}

Check-File (Join-Path $InstallRoot "native-host\native-host.bat") "Native Host launcher"
Check-File (Join-Path $InstallRoot "native-host\native-host.cjs") "Native Host bundle"
Check-File (Join-Path $InstallRoot "extension\manifest.json") "Extension"
Check-File (Join-Path $AppConfigRoot "config.json") "Configuration"

$foundManifest = $false
$braveChannelNames = @("Brave-Browser", "Brave-Browser-Beta", "Brave-Browser-Dev")
foreach ($channelName in $braveChannelNames) {
    $keyPath = "HKCU:\Software\BraveSoftware\$channelName\NativeMessagingHosts\$HostName"
    if (Test-Path $keyPath) {
        $value = (Get-ItemProperty -Path $keyPath -Name "(default)").'(default)'
        Write-Host "[ok] Native Host registry key: $keyPath -> $value"
        $foundManifest = $true
    }
}

if (-not $foundManifest) {
    Write-Host "[missing] No Brave Native Host registry key found"
    $failures++
}

Write-Host "[info] Expected extension ID: $ExtensionId"
Write-Host "[info] Load unpacked directory: $(Join-Path $InstallRoot 'extension')"
Write-Host "[info] Native log: $(Join-Path $InstallRoot 'logs\native-host.log')"

if ($failures -gt 0) {
    Write-Host "Doctor found $failures problem(s)."
    exit 1
}
Write-Host "All installation checks passed."
