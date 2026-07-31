#Requires -Version 5.1
<#
  Uninstalls the YouTube Music Discord Presence Native Host for the
  current Windows user. Works on both Windows 10 and Windows 11.
#>
[CmdletBinding()]
param(
    [switch]$Purge
)

$ErrorActionPreference = "Stop"

$HostName = "dev.ayaka.youtube_music_discord_presence"
$InstallRoot = Join-Path $env:LOCALAPPDATA "youtube-music-discord-presence"
$AppConfigRoot = Join-Path $env:APPDATA "youtube-music-discord-presence"

$braveChannelNames = @("Brave-Browser", "Brave-Browser-Beta", "Brave-Browser-Dev")
foreach ($channelName in $braveChannelNames) {
    $keyPath = "HKCU:\Software\BraveSoftware\$channelName\NativeMessagingHosts\$HostName"
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Force
        Write-Host "Removed registry key: $keyPath"
    }
}

if (Test-Path $InstallRoot) {
    Remove-Item -Path $InstallRoot -Recurse -Force
}

if ($Purge -and (Test-Path $AppConfigRoot)) {
    Remove-Item -Path $AppConfigRoot -Recurse -Force
}

Write-Host "Uninstalled. Remove the extension from brave://extensions if it is still listed."
