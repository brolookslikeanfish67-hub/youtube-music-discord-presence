import type { ActivityPayload } from "@ytmdp/shared";

function truncate(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `${value.slice(0, maxLength - 1)}…`;
}

function formatDiscordText(value: string): string {
  const truncated = truncate(value, 128);
  // Discord requires two characters; zero-width padding keeps the display unchanged.
  return [...truncated].length >= 2 ? truncated : `${truncated}\u200B`;
}

export function buildDiscordActivity(activity: ActivityPayload) {
  const artists = truncate(activity.artists.join(", "), 128);
  const paused = activity.playbackState === "paused";
  const correctedPosition = paused
    ? activity.positionSeconds
    : Math.max(0, activity.positionSeconds + (Date.now() - activity.observedAtMs) / 1000);
  const startTimestamp = Date.now() - correctedPosition * 1000;

  return {
    name: "YouTube Music",
    type: 2,
    statusDisplayType: 2,
    details: formatDiscordText(activity.title),
    state: formatDiscordText(paused ? `${artists} · Paused` : artists),
    ...(activity.artworkUrl
      ? {
          largeImageKey: activity.artworkUrl,
          largeImageText: truncate(`${activity.title} — ${artists}`, 128),
        }
      : {}),
    ...(!paused
      ? {
          startTimestamp,
          ...(activity.durationSeconds
            ? { endTimestamp: startTimestamp + activity.durationSeconds * 1000 }
            : {}),
        }
      : {}),
    ...(activity.trackUrl
      ? { buttons: [{ label: "Open in YouTube Music", url: activity.trackUrl }] }
      : {}),
    instance: false,
  };
}
