# Gantles v1 → v2 Migration Report

Source: `tweaks/gantles-migration.sql`. Every score below is preserved **exactly** from the v1 YAML source — this migration ports custom format names and profile structure to the v2 (PCD/SQL) schema, it does not re-tune any scores.

Columns: **Source CF** (v1 YAML name) → **v2 CF** (name as stored in `custom_formats` after this migration) → **Arr** → **Score** (old = new, unchanged) → **Status**.

> Four rows originally referenced a name that had already been renamed upstream by a later, unrelated op (30–66 have no bearing on this — the renames happened in ops 27, 44, 51, all committed to the `german` branch before this migration was written). `scripts/validate-migration.py` caught these as dangling `custom_format_name` references against a freshly built database, and they were corrected before this report was generated. See the **Status** column.


## Gantles WEB-1080p Streaming

| Source CF (v1) | v2 CF | Arr | Score | Status |
|---|---|---|---|---|
| *(same)* | 1080p | sonarr | 50 | unchanged |
| *(same)* | 720p | sonarr | 5 | unchanged |
| *(same)* | 10bit | sonarr | 25 | NEW (created in v2) |
| German DL | German DL (Language) | sonarr | 10000 | renamed upstream — corrected during validation |
| *(same)* | German DL (undefined) | sonarr | 10000 | unchanged |
| *(same)* | German | sonarr | 3000 | unchanged |
| *(same)* | German 1080p Booster | sonarr | 650 | unchanged |
| *(same)* | Language: Not English | sonarr | -11000 | NEW (created in v2) |
| *(same)* | Language: Not Original | sonarr | -5000 | NEW (created in v2) |
| *(same)* | German Subbed | sonarr | -5000 | NEW (created in v2) |
| *(same)* | DD+ ATMOS | sonarr | 550 | unchanged |
| *(same)* | DD+ | sonarr | 500 | unchanged |
| *(same)* | DD | sonarr | 300 | unchanged |
| *(same)* | AAC | sonarr | 200 | unchanged |
| *(same)* | Opus | sonarr | 150 | NEW (created in v2) |
| *(same)* | TrueHD ATMOS | sonarr | -5000 | unchanged |
| *(same)* | TrueHD | sonarr | -5000 | unchanged |
| *(same)* | DTS-HD MA | sonarr | -5000 | unchanged |
| *(same)* | DTS X | sonarr | -5000 | unchanged |
| *(same)* | PCM | sonarr | -5000 | unchanged |
| *(same)* | FLAC | sonarr | -2000 | unchanged |
| *(same)* | DTS | sonarr | -500 | unchanged |
| *(same)* | German Web Tier 01 | sonarr | 2100 | unchanged |
| *(same)* | German Web Tier 02 | sonarr | 1900 | unchanged |
| *(same)* | German Web Tier 03 | sonarr | 1800 | unchanged |
| *(same)* | German Scene | sonarr | 1700 | unchanged |
| *(same)* | German Bluray Tier 01 | sonarr | 2900 | unchanged |
| *(same)* | German Bluray Tier 02 | sonarr | 2650 | unchanged |
| *(same)* | German Bluray Tier 03 | sonarr | 2300 | unchanged |
| *(same)* | WEB Tier 01 | sonarr | 1700 | unchanged |
| *(same)* | WEB Tier 02 | sonarr | 1650 | unchanged |
| *(same)* | WEB Tier 03 | sonarr | 1600 | unchanged |
| *(same)* | HD Bluray Tier 01 | sonarr | 1800 | unchanged |
| *(same)* | HD Bluray Tier 02 | sonarr | 1750 | unchanged |
| *(same)* | HD Streaming Boost | sonarr | 75 | unchanged |
| Repack&Proper | Repack/Proper | sonarr | 5 | renamed (v1 name → v2 canonical name) |
| *(same)* | Repack2 | sonarr | 6 | unchanged |
| *(same)* | Repack3 | sonarr | 7 | unchanged |
| *(same)* | DV Boost | sonarr | -35000 | unchanged |
| *(same)* | WiTH AD | sonarr | -35000 | unchanged |
| *(same)* | German LQ | sonarr | -35000 | unchanged |
| *(same)* | German LQ (release title) | sonarr | -35000 | unchanged |
| *(same)* | German Microsized | sonarr | -35000 | unchanged |
| *(same)* | BR-DISK | sonarr | -35000 | unchanged |
| *(same)* | LQ | sonarr | -35000 | unchanged |
| *(same)* | LQ (Release Title) | sonarr | -35000 | unchanged |
| *(same)* | Extras | sonarr | -35000 | unchanged |
| *(same)* | AV1 | sonarr | -35000 | unchanged |
| *(same)* | Upscaled | sonarr | -35000 | unchanged |
| *(same)* | No-RlsGroup | sonarr | -35000 | unchanged |
| *(same)* | Obfuscated | sonarr | -35000 | unchanged |
| *(same)* | Retags | sonarr | -35000 | unchanged |
| *(same)* | Bad Dual Groups | sonarr | -35000 | unchanged |
| *(same)* | Hardcoded Subs | sonarr | -35000 | NEW (created in v2) |
| x266 | x266 (Codec) | sonarr | -35000 | renamed upstream — corrected during validation |
| *(same)* | VP9 | sonarr | -35000 | unchanged |
| *(same)* | MPEG2 | sonarr | -35000 | unchanged |
| *(same)* | VC-1 | sonarr | -35000 | unchanged |
| *(same)* | MP3 | sonarr | -35000 | NEW (created in v2) |
| *(same)* | 1080p | radarr | 50 | unchanged |
| *(same)* | 720p | radarr | 5 | unchanged |
| *(same)* | 10bit | radarr | 25 | NEW (created in v2) |
| German DL | German DL (Language) | radarr | 10000 | renamed upstream — corrected during validation |
| *(same)* | German DL (undefined) | radarr | 10000 | unchanged |
| *(same)* | German | radarr | 3000 | unchanged |
| *(same)* | German 1080p Booster | radarr | 650 | unchanged |
| *(same)* | Language: Not English | radarr | -11000 | NEW (created in v2) |
| *(same)* | Language: Not Original | radarr | -5000 | NEW (created in v2) |
| *(same)* | German Subbed | radarr | -5000 | NEW (created in v2) |
| *(same)* | DD+ ATMOS | radarr | 550 | unchanged |
| *(same)* | DD+ | radarr | 500 | unchanged |
| *(same)* | DD | radarr | 300 | unchanged |
| *(same)* | AAC | radarr | 200 | unchanged |
| *(same)* | Opus | radarr | 150 | NEW (created in v2) |
| *(same)* | TrueHD ATMOS | radarr | -5000 | unchanged |
| *(same)* | TrueHD | radarr | -5000 | unchanged |
| *(same)* | DTS-HD MA | radarr | -5000 | unchanged |
| *(same)* | DTS X | radarr | -5000 | unchanged |
| *(same)* | PCM | radarr | -5000 | unchanged |
| *(same)* | FLAC | radarr | -2000 | unchanged |
| *(same)* | DTS | radarr | -500 | unchanged |
| *(same)* | Generated Dynamic HDR | radarr | -10000 | unchanged |
| *(same)* | German Web Tier 01 | radarr | 2100 | unchanged |
| *(same)* | German Web Tier 02 | radarr | 1900 | unchanged |
| *(same)* | German Web Tier 03 | radarr | 1800 | unchanged |
| *(same)* | German Scene | radarr | 1700 | unchanged |
| *(same)* | German Bluray Tier 01 | radarr | 2900 | unchanged |
| *(same)* | German Bluray Tier 02 | radarr | 2650 | unchanged |
| *(same)* | German Bluray Tier 03 | radarr | 2300 | unchanged |
| *(same)* | WEB Tier 01 | radarr | 1700 | unchanged |
| *(same)* | WEB Tier 02 | radarr | 1650 | unchanged |
| *(same)* | WEB Tier 03 | radarr | 1600 | unchanged |
| *(same)* | HD Bluray Tier 01 | radarr | 1800 | unchanged |
| *(same)* | HD Bluray Tier 02 | radarr | 1750 | unchanged |
| *(same)* | HD Bluray Tier 03 | radarr | 1700 | unchanged |
| Repack&Proper | Repack/Proper | radarr | 5 | renamed (v1 name → v2 canonical name) |
| *(same)* | Repack2 | radarr | 6 | unchanged |
| *(same)* | Repack3 | radarr | 7 | unchanged |
| *(same)* | DV Boost | radarr | -35000 | unchanged |
| *(same)* | WiTH AD | radarr | -35000 | unchanged |
| *(same)* | German LQ | radarr | -35000 | unchanged |
| *(same)* | German LQ (release title) | radarr | -35000 | unchanged |
| *(same)* | German Microsized | radarr | -35000 | unchanged |
| Line&Mic Dubbed | Line/Mic Dubbed | radarr | -35000 | renamed (v1 name → v2 canonical name) |
| *(same)* | BR-DISK | radarr | -35000 | unchanged |
| *(same)* | LQ | radarr | -35000 | unchanged |
| *(same)* | LQ (Release Title) | radarr | -35000 | unchanged |
| *(same)* | 3D | radarr | -35000 | unchanged |
| *(same)* | Extras | radarr | -35000 | unchanged |
| *(same)* | AV1 | radarr | -35000 | unchanged |
| *(same)* | Upscaled | radarr | -35000 | unchanged |
| *(same)* | No-RlsGroup | radarr | -35000 | unchanged |
| *(same)* | Obfuscated | radarr | -35000 | unchanged |
| *(same)* | Retags | radarr | -35000 | unchanged |
| *(same)* | Bad Dual Groups | radarr | -35000 | unchanged |
| *(same)* | Hardcoded Subs | radarr | -35000 | NEW (created in v2) |
| x266 | x266 (Codec) | radarr | -35000 | renamed upstream — corrected during validation |
| *(same)* | VP9 | radarr | -35000 | unchanged |
| *(same)* | MPEG2 | radarr | -35000 | unchanged |
| *(same)* | VC-1 | radarr | -35000 | unchanged |
| *(same)* | MP3 | radarr | -35000 | NEW (created in v2) |
| *(same)* | Sing-Along Versions | radarr | -35000 | unchanged |

## Gantles WEB-2160p Streaming

| Source CF (v1) | v2 CF | Arr | Score | Status |
|---|---|---|---|---|
| *(same)* | 2160p | sonarr | 100 | unchanged |
| *(same)* | 1080p | sonarr | 50 | unchanged |
| *(same)* | 720p | sonarr | 5 | unchanged |
| *(same)* | 10bit | sonarr | 50 | NEW (created in v2) |
| German DL | German DL (Language) | sonarr | 10000 | renamed upstream — corrected during validation |
| *(same)* | German DL (undefined) | sonarr | 10000 | unchanged |
| *(same)* | German | sonarr | 3000 | unchanged |
| *(same)* | German 2160p Booster | sonarr | 9000 | unchanged |
| *(same)* | German 1080p Booster | sonarr | 650 | unchanged |
| *(same)* | Language: Not English | sonarr | -11000 | NEW (created in v2) |
| *(same)* | Language: Not Original | sonarr | -5000 | NEW (created in v2) |
| *(same)* | German Subbed | sonarr | -5000 | NEW (created in v2) |
| *(same)* | DD+ ATMOS | sonarr | 550 | unchanged |
| *(same)* | DD+ | sonarr | 500 | unchanged |
| *(same)* | DD | sonarr | 300 | unchanged |
| *(same)* | AAC | sonarr | 200 | unchanged |
| *(same)* | Opus | sonarr | 150 | NEW (created in v2) |
| *(same)* | TrueHD ATMOS | sonarr | -5000 | unchanged |
| *(same)* | TrueHD | sonarr | -5000 | unchanged |
| *(same)* | DTS-HD MA | sonarr | -5000 | unchanged |
| *(same)* | DTS X | sonarr | -5000 | unchanged |
| *(same)* | PCM | sonarr | -5000 | unchanged |
| *(same)* | FLAC | sonarr | -2000 | unchanged |
| *(same)* | DTS | sonarr | -500 | unchanged |
| *(same)* | German Web Tier 01 | sonarr | 2100 | unchanged |
| *(same)* | German Web Tier 02 | sonarr | 1900 | unchanged |
| *(same)* | German Web Tier 03 | sonarr | 1800 | unchanged |
| *(same)* | German Scene | sonarr | 1700 | unchanged |
| *(same)* | WEB Tier 01 | sonarr | 1700 | unchanged |
| *(same)* | WEB Tier 02 | sonarr | 1650 | unchanged |
| *(same)* | WEB Tier 03 | sonarr | 1600 | unchanged |
| *(same)* | HD Streaming Boost | sonarr | 75 | unchanged |
| *(same)* | UHD Streaming Boost | sonarr | 75 | unchanged |
| Repack&Proper | Repack/Proper | sonarr | 5 | renamed (v1 name → v2 canonical name) |
| *(same)* | Repack2 | sonarr | 6 | unchanged |
| *(same)* | Repack3 | sonarr | 7 | unchanged |
| HDR10+ Boost | HDR10Plus Boost | sonarr | 1000 | renamed (v1 name → v2 canonical name) |
| HDR | HDR10 | sonarr | 500 | renamed upstream — corrected during validation |
| *(same)* | HLG | sonarr | 250 | NEW (created in v2) |
| *(same)* | DV Boost | sonarr | 1500 | unchanged |
| DV (w&o HDR ...) | DV (w/o HDR fallback) | sonarr | -35000 | renamed (v1 name → v2 canonical name) |
| *(same)* | DV (Disk) | sonarr | -35000 | unchanged |
| *(same)* | Remux Tier 01 | sonarr | -35000 | unchanged |
| *(same)* | Remux Tier 02 | sonarr | -35000 | unchanged |
| *(same)* | WiTH AD | sonarr | -35000 | unchanged |
| *(same)* | German LQ | sonarr | -35000 | unchanged |
| *(same)* | German LQ (release title) | sonarr | -35000 | unchanged |
| *(same)* | German Microsized | sonarr | -35000 | unchanged |
| *(same)* | BR-DISK | sonarr | -35000 | unchanged |
| *(same)* | LQ | sonarr | -35000 | unchanged |
| *(same)* | LQ (Release Title) | sonarr | -35000 | unchanged |
| *(same)* | Extras | sonarr | -35000 | unchanged |
| *(same)* | AV1 | sonarr | -35000 | unchanged |
| *(same)* | Upscaled | sonarr | -35000 | unchanged |
| *(same)* | No-RlsGroup | sonarr | -35000 | unchanged |
| *(same)* | Obfuscated | sonarr | -35000 | unchanged |
| *(same)* | Retags | sonarr | -35000 | unchanged |
| *(same)* | Bad Dual Groups | sonarr | -35000 | unchanged |
| *(same)* | Hardcoded Subs | sonarr | -35000 | NEW (created in v2) |
| x266 | x266 (Codec) | sonarr | -35000 | renamed upstream — corrected during validation |
| *(same)* | VP9 | sonarr | -35000 | unchanged |
| *(same)* | MPEG2 | sonarr | -35000 | unchanged |
| *(same)* | VC-1 | sonarr | -35000 | unchanged |
| *(same)* | MP3 | sonarr | -35000 | NEW (created in v2) |
| *(same)* | 2160p | radarr | 100 | unchanged |
| *(same)* | 1080p | radarr | 50 | unchanged |
| *(same)* | 720p | radarr | 5 | unchanged |
| *(same)* | 10bit | radarr | 50 | NEW (created in v2) |
| German DL | German DL (Language) | radarr | 10000 | renamed upstream — corrected during validation |
| *(same)* | German DL (undefined) | radarr | 10000 | unchanged |
| *(same)* | German | radarr | 3000 | unchanged |
| *(same)* | German 2160p Booster | radarr | 9000 | unchanged |
| *(same)* | German 1080p Booster | radarr | 650 | unchanged |
| *(same)* | Language: Not English | radarr | -11000 | NEW (created in v2) |
| *(same)* | Language: Not Original | radarr | -5000 | NEW (created in v2) |
| *(same)* | German Subbed | radarr | -5000 | NEW (created in v2) |
| *(same)* | DD+ ATMOS | radarr | 550 | unchanged |
| *(same)* | DD+ | radarr | 500 | unchanged |
| *(same)* | DD | radarr | 300 | unchanged |
| *(same)* | AAC | radarr | 200 | unchanged |
| *(same)* | Opus | radarr | 150 | NEW (created in v2) |
| *(same)* | TrueHD ATMOS | radarr | -5000 | unchanged |
| *(same)* | TrueHD | radarr | -5000 | unchanged |
| *(same)* | DTS-HD MA | radarr | -5000 | unchanged |
| *(same)* | DTS X | radarr | -5000 | unchanged |
| *(same)* | PCM | radarr | -5000 | unchanged |
| *(same)* | FLAC | radarr | -2000 | unchanged |
| *(same)* | DTS | radarr | -500 | unchanged |
| NOT: IMAX Enhanced | IMAX Enhanced | radarr | 100 | renamed upstream — corrected during validation |
| *(same)* | IMAX | radarr | 50 | unchanged |
| HDR10+ Boost | HDR10Plus Boost | radarr | 1000 | renamed (v1 name → v2 canonical name) |
| HDR | HDR10 | radarr | 500 | renamed upstream — corrected during validation |
| *(same)* | HLG | radarr | 250 | NEW (created in v2) |
| *(same)* | DV Boost | radarr | 1500 | unchanged |
| DV (w&o HDR ...) | DV (w/o HDR fallback) | radarr | -35000 | renamed (v1 name → v2 canonical name) |
| *(same)* | DV (Disk) | radarr | -35000 | unchanged |
| *(same)* | Generated Dynamic HDR | radarr | -10000 | unchanged |
| *(same)* | German Web Tier 01 | radarr | 2100 | unchanged |
| *(same)* | German Web Tier 02 | radarr | 1900 | unchanged |
| *(same)* | German Web Tier 03 | radarr | 1800 | unchanged |
| *(same)* | German Scene | radarr | 1700 | unchanged |
| *(same)* | WEB Tier 01 | radarr | 1700 | unchanged |
| *(same)* | WEB Tier 02 | radarr | 1650 | unchanged |
| *(same)* | WEB Tier 03 | radarr | 1600 | unchanged |
| Repack&Proper | Repack/Proper | radarr | 5 | renamed (v1 name → v2 canonical name) |
| *(same)* | Repack2 | radarr | 6 | unchanged |
| *(same)* | Repack3 | radarr | 7 | unchanged |
| *(same)* | Remux Tier 01 | radarr | -35000 | unchanged |
| *(same)* | Remux Tier 02 | radarr | -35000 | unchanged |
| *(same)* | Remux Tier 03 | radarr | -35000 | unchanged |
| *(same)* | WiTH AD | radarr | -35000 | unchanged |
| *(same)* | German LQ | radarr | -35000 | unchanged |
| *(same)* | German LQ (release title) | radarr | -35000 | unchanged |
| *(same)* | German Microsized | radarr | -35000 | unchanged |
| Line&Mic Dubbed | Line/Mic Dubbed | radarr | -35000 | renamed (v1 name → v2 canonical name) |
| *(same)* | BR-DISK | radarr | -35000 | unchanged |
| *(same)* | LQ | radarr | -35000 | unchanged |
| *(same)* | LQ (Release Title) | radarr | -35000 | unchanged |
| *(same)* | 3D | radarr | -35000 | unchanged |
| *(same)* | Upscaled | radarr | -35000 | unchanged |
| *(same)* | Extras | radarr | -35000 | unchanged |
| *(same)* | AV1 | radarr | -35000 | unchanged |
| *(same)* | No-RlsGroup | radarr | -35000 | unchanged |
| *(same)* | Obfuscated | radarr | -35000 | unchanged |
| *(same)* | Retags | radarr | -35000 | unchanged |
| *(same)* | Bad Dual Groups | radarr | -35000 | unchanged |
| *(same)* | Hardcoded Subs | radarr | -35000 | NEW (created in v2) |
| x266 | x266 (Codec) | radarr | -35000 | renamed upstream — corrected during validation |
| *(same)* | VP9 | radarr | -35000 | unchanged |
| *(same)* | MPEG2 | radarr | -35000 | unchanged |
| *(same)* | VC-1 | radarr | -35000 | unchanged |
| *(same)* | MP3 | radarr | -35000 | NEW (created in v2) |
| *(same)* | Sing-Along Versions | radarr | -35000 | unchanged |

## Summary

- Total score entries: 255
- Unchanged name (v1 == v2): 204
- Renamed (documented v1 → v2 canonical mapping): 10
- Renamed upstream, corrected during validation: 11
- Brand-new custom formats created by this migration: 30

New custom formats (created in Part 2 of the migration): `10bit`, `German Subbed`, `HLG`, `Hardcoded Subs`, `Language: Not English`, `Language: Not Original`, `MP3`, `Opus`
