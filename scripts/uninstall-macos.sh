#!/usr/bin/env bash
set -euo pipefail

HOST_NAME="dev.ayaka.youtube_music_discord_presence"
APP_SUPPORT="$HOME/Library/Application Support/youtube-music-discord-presence"
PURGE_CONFIG=false

if [[ "${1:-}" == "--purge" ]]; then
  PURGE_CONFIG=true
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--purge]" >&2
  exit 2
fi

for profile_root in \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser-Beta" \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser-Dev"
do
  manifest="$profile_root/NativeMessagingHosts/$HOST_NAME.json"
  if [[ -f "$manifest" ]]; then
    rm -- "$manifest"
    echo "Removed: $manifest"
  fi
done

rm -rf -- "$HOME/Library/Logs/youtube-music-discord-presence"

if [[ "$PURGE_CONFIG" == true ]]; then
  rm -rf -- "$APP_SUPPORT"
else
  rm -rf -- "$APP_SUPPORT/native-host" "$APP_SUPPORT/extension"
fi

echo "Uninstalled. Remove the extension from brave://extensions if it is still listed."
