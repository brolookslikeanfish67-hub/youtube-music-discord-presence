#Requires -Version 5.1
<#
  Installs the YouTube Music Discord Presence Native Host and extension
  build for the current Windows user. Works on both Windows 10 and
  Windows 11 (the Chrome/Brave Native Messaging mechanism is identical
  on both).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ClientId
)

$ErrorActionPreference = "Stop"

$HostName = "dev.ayaka.youtube_music_discord_presence"
$ExtensionId = "klebilgcaopidgkbffhnffgjljegimno"
$RootDir = Split-Path -Parent $PSScriptRoot

if ($ClientId -notmatch '^\d{17,20}$') {
    Write-Error "-ClientId must be a 17-20 digit Discord Application ID."
    exit 2
}

$ExtensionManifest = Join-Path $RootDir "packages\extension\dist\manifest.json"
$NativeHostBundle = Join-Path $RootDir "packages\native-host\dist\native-host.cjs"

if (-not (Test-Path $ExtensionManifest) -or -not (Test-Path $NativeHostBundle)) {
    Write-Host "Build output is missing; running pnpm build..."
    Push-Location $RootDir
    try {
        pnpm build
        if ($LASTEXITCODE -ne 0) { throw "pnpm build failed" }
    } finally {
        Pop-Location
    }
}

$NodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCmd) {
    Write-Error "Node.js was not found on PATH."
    exit 1
}
$NodePath = $NodeCmd.Source

$InstallRoot = Join-Path $env:LOCALAPPDATA "youtube-music-discord-presence"
$HostRoot = Join-Path $InstallRoot "native-host"
$ExtensionRoot = Join-Path $InstallRoot "extension"
$AppConfigRoot = Join-Path $env:APPDATA "youtube-music-discord-presence"
$LogRoot = Join-Path $InstallRoot "logs"
$Wrapper = Join-Path $HostRoot "native-host.bat"
$ManifestPath = Join-Path $HostRoot "$HostName.json"

New-Item -ItemType Directory -Force -Path $HostRoot, $ExtensionRoot, $AppConfigRoot, $LogRoot | Out-Null

Copy-Item -Path (Join-Path $RootDir "packages\native-host\dist\native-host.cjs") -Destination (Join-Path $HostRoot "native-host.cjs") -Force
$MapFile = Join-Path $RootDir "packages\native-host\dist\native-host.cjs.map"
if (Test-Path $MapFile) {
    Copy-Item -Path $MapFile -Destination (Join-Path $HostRoot "native-host.cjs.map") -Force
}
Copy-Item -Path (Join-Path $RootDir "packages\extension\dist\*") -Destination $ExtensionRoot -Recurse -Force

$ConfigJson = @"
{
  "discordClientId": "$ClientId"
}
"@
Set-Content -Path (Join-Path $AppConfigRoot "config.json") -Value $ConfigJson -Encoding UTF8

$LogFile = Join-Path $LogRoot "native-host.log"
$WrapperContent = "@echo off`r`n`"$NodePath`" `"$HostRoot\native-host.cjs`" 2>>`"$LogFile`"`r`n"
Set-Content -Path $Wrapper -Value $WrapperContent -Encoding ASCII

$ManifestJson = @"
{
  "name": "$HostName",
  "description": "YouTube Music Discord Presence Native Host",
  "path": "$($Wrapper -replace '\\', '\\\\')",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$ExtensionId/"
  ]
}
"@
Set-Content -Path $ManifestPath -Value $ManifestJson -Encoding UTF8

$installed = 0
$braveChannels = @(
    @{ Name = "Brave-Browser";      UserData = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data" },
    @{ Name = "Brave-Browser-Beta"; UserData = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser-Beta\User Data" },
    @{ Name = "Brave-Browser-Dev";  UserData = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser-Dev\User Data" }
)
foreach ($channel in $braveChannels) {
    if (Test-Path $channel.UserData) {
        $keyPath = "HKCU:\Software\BraveSoftware\$($channel.Name)\NativeMessagingHosts\$HostName"
        New-Item -Path $keyPath -Force | Out-Null
        Set-ItemProperty -Path $keyPath -Name "(default)" -Value $ManifestPath
        Write-Host "Registered Native Host for: $($channel.UserData)"
        $installed++
    }
}

if ($installed -eq 0) {
    Write-Error "No Brave profile was found under $env:LOCALAPPDATA\BraveSoftware."
    exit 1
}

Write-Host ""
Write-Host "Installed successfully."
Write-Host "Extension directory: $ExtensionRoot"
Write-Host "Extension ID:        $ExtensionId"
Write-Host ""
Write-Host "Open brave://extensions, enable Developer mode, click Load unpacked,"
Write-Host "and select the extension directory above. Then restart Brave."
