#!/usr/bin/env bash
set -u

HOST_NAME="dev.ayaka.youtube_music_discord_presence"
EXTENSION_ID="klebilgcaopidgkbffhnffgjljegimno"
APP_SUPPORT="$HOME/Library/Application Support/youtube-music-discord-presence"
INSTALL_ROOT="$APP_SUPPORT"
failures=0

check_file() {
  if [[ -f "$1" ]]; then
    echo "[ok] $2: $1"
  else
    echo "[missing] $2: $1"
    failures=$((failures + 1))
  fi
}

if command -v node >/dev/null 2>&1; then
  echo "[ok] Node: $(node --version) ($(command -v node))"
else
  echo "[missing] Node.js"
  failures=$((failures + 1))
fi

if [[ -d "/Applications/Brave Browser Beta.app" ]] || command -v brave-browser-beta >/dev/null 2>&1; then
  echo "[ok] Brave Beta found"
else
  echo "[missing] Brave Browser Beta.app"
  failures=$((failures + 1))
fi

if [[ -d "/Applications/Discord.app" ]] || command -v discord >/dev/null 2>&1; then
  echo "[ok] Discord found"
else
  echo "[missing] Discord.app"
  failures=$((failures + 1))
fi

check_file "$INSTALL_ROOT/native-host/native-host" "Native Host launcher"
check_file "$INSTALL_ROOT/native-host/native-host.cjs" "Native Host bundle"
check_file "$INSTALL_ROOT/extension/manifest.json" "Extension"
check_file "$APP_SUPPORT/config.json" "Configuration"

found_manifest=false
for profile_root in \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser-Beta" \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser-Dev"
do
  manifest="$profile_root/NativeMessagingHosts/$HOST_NAME.json"
  if [[ -f "$manifest" ]]; then
    echo "[ok] Native Host manifest: $manifest"
    found_manifest=true
  fi
done

if [[ "$found_manifest" == false ]]; then
  echo "[missing] No Brave Native Host manifest found"
  failures=$((failures + 1))
fi

echo "[info] Expected extension ID: $EXTENSION_ID"
echo "[info] Load unpacked directory: $INSTALL_ROOT/extension"
echo "[info] Native log: $HOME/Library/Logs/youtube-music-discord-presence/native-host.log"

if [[ $failures -gt 0 ]]; then
  echo "Doctor found $failures problem(s)."
  exit 1
fi
echo "All installation checks passed."
