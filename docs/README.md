# Gantles Profiles — Language Scoring Logic

## Overview

The Gantles WEB-1080p and WEB-2160p Streaming profiles use a **7-tier language preference system** based on custom format scoring. Instead of hard-rejecting releases that lack certain languages, every release is scored — the system grabs whatever is available first and automatically upgrades toward the ideal version over time.

## Language Tiers

| Tier | Languages in release | Base score | Behavior |
|------|---------------------|-----------|----------|
| 1 | Native + English + German | ~+10,000 | **Best** — stops upgrading |
| 2 | Native + English | ~0 | Upgrades when German appears |
| 3 | Native + German | ~-1,000 | Upgrades when English appears |
| 4 | English + German | ~-2,000 | Upgrades when Native appears |
| 5 | English only | ~-5,000 | Upgrades when German/Native appears |
| 6 | Native only | ~-11,000 | Upgrades when English/German appears |
| 7 | German only | ~-13,000 | Last resort — upgrades toward any better tier |

> **Note:** "Native" means the original language of the movie/show as set in TMDB metadata. For an English movie, English IS the native language — so an English-only release is already tier 2, not tier 5.

## Custom Formats Used

### Language bonuses (positive scores)

| Custom Format | Score | What it detects |
|--------------|-------|-----------------|
| `German DL` | +10,000 | Release has **Original + German** audio (dual language) |
| `German DL (undefined)` | +10,000 | Same as above, less certain detection |
| `German` | +3,000 | Release has German audio but **not** the original language |

### Language penalties (negative scores)

| Custom Format | Score | What it detects |
|--------------|-------|-----------------|
| `Language: Not English` | -11,000 | Release does **not** contain English audio |
| `Language: Not Original` | -5,000 | Release does **not** contain the original/native audio |

### How the math works

Each custom format fires independently. The scores are additive:

**Tier 1 — Native + English + German:**
- `German DL` fires (+10,000) — has German + Original
- No penalties fire
- **Total: +10,000**

**Tier 2 — Native + English (no German):**
- No language CFs fire
- **Total: 0**

**Tier 3 — Native + German (no English):**
- `German DL` fires (+10,000) — has German + Original
- `Not English` fires (-11,000)
- **Total: -1,000**

**Tier 4 — English + German (no Native):**
- `German` fires (+3,000) — has German, no Original
- `Not Original` fires (-5,000)
- **Total: -2,000**

**Tier 5 — English only:**
- `Not Original` fires (-5,000)
- **Total: -5,000**

**Tier 6 — Native only (no English, no German):**
- `Not English` fires (-11,000)
- **Total: -11,000**

**Tier 7 — German only (no English, no Native):**
- `German` fires (+3,000)
- `Not English` fires (-11,000)
- `Not Original` fires (-5,000)
- **Total: -13,000**

## When Native = English or German

The tiers collapse naturally:

### English movie (e.g., Inception)
- English-only release → Native ✓ + English ✓ → **Tier 2** (not tier 5)
- German DL release → Native ✓ + English ✓ + German ✓ → **Tier 1**

### German movie (e.g., Das Boot)
- German-only release → Native ✓ + German ✓ → **Tier 3** (not tier 7)
- German + English release → Native ✓ + English ✓ + German ✓ → **Tier 1**

### Non-English/German movie (e.g., Spirited Away)
- All 7 tiers are reachable since Japanese, English, and German are distinct languages

## Profile Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `language` | `any` | No hard language gate — scoring handles preference |
| `minCustomFormatScore` | `-15000` | Allows all 7 tiers to be grabbed |
| `upgradeUntilScore` | `35000` | Keeps upgrading until the best tier + best group |
| `upgradesAllowed` | `true` | Enables the automatic upgrade ladder |

## Real-World Example: Adding "Spirited Away" (Japanese)

1. Radarr finds `Spirited.Away.1080p.WEB-DL.English` → tier 5 (score ~-3,300 with group bonus) → **grabbed**
2. Later: `Spirited.Away.1080p.WEB-DL.German.English` → tier 4 (score ~-300) → **upgrade!**
3. Later: `Spirited.Away.1080p.WEB-DL.Japanese.English` → tier 2 (score ~1,700) → **upgrade!**
4. Later: `Spirited.Away.1080p.WEB-DL.Japanese.English.German.DL` → tier 1 (score ~11,700) → **upgrade! (final)**

## Differences Between 1080p and 2160p Profiles

Both profiles share the same language logic. The 2160p profile adds:

- **Resolution boosters:** 2160p (+100) in addition to 1080p (+50)
- **German resolution boosters:** German 2160p Booster (+9,000), German 1080p Booster (+650)
- **Smart Dolby Vision:** DV Boost (+1,500) for DV with HDR10 fallback; DV w/o HDR fallback (-35,000) banned
- **HDR scoring:** HDR10+ Boost (+1,000), HDR (+500)
- **HDR bans:** DV without HDR fallback (-35,000), DV from disk (-35,000), Generated Dynamic HDR (-10,000)
- **Quality fallback:** Accepts WEB 1080p as fallback while waiting for 4K
- **Streaming boosts:** Both HD and UHD streaming boosts (+75 each)
- **Remux bans:** Remux Tier 01/02/03 all at -35,000 (defense in depth for remote streaming)

---

## Remote Streaming Optimization

### Why bitrate matters for remote playback

Remote streaming quality depends on total bitrate — both video and audio combined. High-bitrate files stutter when the remote connection can't sustain the required throughput.

**Real-world examples:**
- ✅ **Emma. (2020) 4K** — 13.39 GB, 2:04:21 runtime, ~15 Mbps, HEVC Main 10 HDR10, EAC3 5.1 → **plays perfectly remotely**
- ❌ **LOTR: Two Towers 4K** — 49.48 GB, 3:55:20 runtime, ~30 Mbps, HEVC Main 10, TrueHD Atmos 7.1 → **stutters remotely**

### Bitrate formula

```
Mbps × 7.5 = MB/min
```

### Bitrate reference table

| Mbps | MB/min | Use case |
|------|--------|----------|
| 6 | 45 | Good 1080p WEB-DL (lower end) |
| 10 | 75 | Good 1080p WEB-DL |
| 12 | 90 | 1080p soft max |
| 15 | 112.5 | 1080p hard max / 4K min acceptable |
| 18 | 135 | 4K preferred target |
| 20 | 150 | 4K soft max (remote-safe ceiling) |
| 25 | 187.5 | 4K hard max (borderline — may stutter) |
| 30 | 225 | 4K Remux territory — **REJECT** |

### Audio format impact on total bitrate

Audio codec choice significantly impacts total file bitrate:

| Audio codec | Typical bitrate | Impact |
|------------|----------------|--------|
| EAC3 (DD+) 5.1 | 0.3–0.6 Mbps | ✅ Minimal — ideal for streaming |
| AC3 (DD) 5.1 | 0.4–0.6 Mbps | ✅ Minimal — good for streaming |
| DTS | 0.8–1.5 Mbps | ⚠️ Moderate — acceptable |
| FLAC | 1–3 Mbps | ⚠️ High — adds noticeable overhead |
| DTS-HD MA | 2–6 Mbps | ❌ Very high — can push total over limits |
| TrueHD Atmos 7.1 | 3–8 Mbps | ❌ Very high — main cause of oversized files |
| PCM | 4–6 Mbps | ❌ Very high — uncompressed, wasteful for streaming |

### Audio scoring in profiles

Both profiles penalize lossless/high-bitrate audio and prefer streaming-friendly codecs:

| Custom Format | Score | Rationale |
|--------------|-------|-----------|
| DD+ (EAC3) | +500 | Standard streaming codec (Netflix, Disney+, etc.) |
| DD+ ATMOS | +450 | Lossy Atmos — streaming-friendly spatial audio |
| DD (AC3) | +300 | Legacy streaming codec — universally compatible |
| DTS | -500 | Higher bitrate than DD/DD+ but not lossless |
| FLAC | -2,000 | Lossless — adds 1-3 Mbps overhead |
| TrueHD | -5,000 | Lossless — adds 3-8 Mbps, often triggers transcoding |
| TrueHD ATMOS | -5,000 | Lossless Atmos — highest bitrate audio format |
| DTS-HD MA | -5,000 | Lossless — equivalent to TrueHD in size impact |
| DTS:X | -5,000 | Object-based lossless — same concerns as DTS-HD MA |
| PCM | -5,000 | Uncompressed — largest possible audio tracks |

### Smart Dolby Vision (2160p profile only)

Instead of banning all Dolby Vision, the 2160p profile uses "smart DV":

| Custom Format | Score | Effect |
|--------------|-------|--------|
| DV Boost | +1,500 | Prefer DV releases (with HDR10 fallback) |
| DV (w&o HDR fallback) | -35,000 | **Ban** DV without HDR10 fallback (causes issues on non-DV devices) |
| DV (Disk) | -35,000 | **Ban** disk-based DV (irrelevant for WEB-only profiles) |

**Result:** Only DV releases with HDR10 fallback are accepted. DV-capable devices get Dolby Vision; others fall back to HDR10 seamlessly.

The 1080p profile bans all DV (`DV Boost: -35,000`) since DV at 1080p is rare and not beneficial.

### Recommended quality definition values

Since quality definitions in Profilarr are global (not per-profile), and you run separate 1080p and 4K instances, set these values **directly in each *arr instance**:

#### Radarr — 4K instance (quality definitions)

| Quality | Min (MB/min) | Preferred (MB/min) | Max (MB/min) |
|---------|-------------|-------------------|-------------|
| WEBDL-2160p | 0 | 150 | 187 |
| WEBRip-2160p | 0 | 150 | 187 |
| WEBDL-1080p | 0 | 90 | 112 |
| WEBRip-1080p | 0 | 90 | 112 |

#### Radarr — 1080p instance (quality definitions)

| Quality | Min (MB/min) | Preferred (MB/min) | Max (MB/min) |
|---------|-------------|-------------------|-------------|
| WEBDL-1080p | 0 | 90 | 112 |
| WEBRip-1080p | 0 | 90 | 112 |
| Bluray-1080p | 0 | 90 | 112 |

#### Sonarr — 4K instance (quality definitions)

| Quality | Min (MB/min) | Preferred (MB/min) | Max (MB/min) |
|---------|-------------|-------------------|-------------|
| WEBDL-2160p | 0 | 150 | 187 |
| WEBRip-2160p | 0 | 150 | 187 |
| WEBDL-1080p | 0 | 90 | 112 |
| WEBRip-1080p | 0 | 90 | 112 |

#### Sonarr — 1080p instance (quality definitions)

| Quality | Min (MB/min) | Preferred (MB/min) | Max (MB/min) |
|---------|-------------|-------------------|-------------|
| WEBDL-1080p | 0 | 90 | 112 |
| WEBRip-1080p | 0 | 90 | 112 |
| Bluray-1080p | 0 | 90 | 112 |

> **Note:** These MB/min values are set in the Radarr/Sonarr UI under Settings → Quality. Profilarr's global `quality_definitions.yml` is left at max=2000 (uncapped) since it's shared across all profiles. The per-instance values above should be set directly in each *arr instance.