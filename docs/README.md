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
- **HDR scoring:** DV Boost (+1,500), HDR10+ Boost (+1,000), HDR (+500)
- **HDR bans:** DV without HDR fallback (-35,000), DV from disk (-35,000), Generated Dynamic HDR (-10,000)
- **Quality fallback:** Accepts WEB 1080p as fallback while waiting for 4K
- **Streaming boosts:** Both HD and UHD streaming boosts (+75 each)