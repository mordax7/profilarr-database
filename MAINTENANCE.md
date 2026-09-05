# Maintaining the Gantles Profiles

This repo is a fork of [`Dictionarry-Hub/trash-pcd`](https://github.com/Dictionarry-Hub/trash-pcd)
(branch `german`), with two personal quality profiles — `Gantles WEB-1080p
Streaming` and `Gantles WEB-2160p Streaming` — layered on top in
`tweaks/gantles-migration.sql`. This document explains the repo layout, how
those profiles reach a Profilarr instance, and how to keep them in sync with
upstream changes.

## Why a fork, not a standalone database

Of the 255 custom-format score rows across the two Gantles profiles, 204
reference custom formats that live in the upstream German TRaSH catalog
(release-group tiers, audio/HDR formats, repack handling, etc.) — only 8 are
new formats created specifically for these profiles. Those 204 are
community-maintained: upstream regularly patches them (new release groups,
regex fixes, drift corrections — see commits like `Fix German Bluray Tier 03`
or `Fix Black and White Edition CFs` in this repo's history).

Staying a fork means every such upstream fix reaches the Gantles profiles for
free the next time this repo is synced from `trash-pcd`. A standalone,
extracted copy would freeze those 204 formats at a point in time — you'd have
to manually notice and re-port every future upstream fix yourself.

## Repo layout

| Path                | Owner              | What it is                                                                 |
| -------------------- | ------------------ | --------------------------------------------------------------------------- |
| `ops/`               | Upstream (trash-pcd) | The base PCD layer — the full German TRaSH catalog. **Never edit by hand.** |
| `tweaks/`             | You                 | Personal content layered on top, applied after all of `ops/` compiles. `gantles-migration.sql` lives here. |
| `scripts/`            | You (tooling)       | `validate-migration.py` / `build-test-db.py` — offline checks that replay `schema → ops → tweaks` into a throwaway SQLite DB, since there's no live Profilarr instance to validate against while editing. |
| `scripts/schema/`     | Vendored            | A copy of [`Dictionarry-Hub/schema`](https://github.com/Dictionarry-Hub/schema)'s `ops/`, needed because this repo has no `CREATE TABLE`s of its own — Profilarr supplies the schema at compile time, so the validator has to vendor a copy to build a database offline. |
| `migration-report.md` | Generated           | Full source→v2 mapping table for the migration. Regenerate with `python3 scripts/generate-migration-report.py` after any change to `tweaks/gantles-migration.sql`. |
| `main` branch         | You (archive)       | The original v1 YAML-format source (`profiles/Gantles WEB-*.yml`) that `tweaks/gantles-migration.sql` was ported from. Kept untouched as the historical record; not a PCD (no `pcd.json`), so it cannot be linked in Profilarr directly. |

Profilarr's real compile order is `schema → base (ops/) → tweaks (tweaks/) →
user`. The scripts in `scripts/` mirror that order so a local check means
something.

## Getting this into Profilarr

1. **Databases → + → Link Database** in Profilarr.
2. Repository URL: `https://github.com/mordax7/profilarr-database`
3. Branch: `v2` (cannot be changed after linking — double check before saving)
4. Personal Access Token: only needed for a private repo or to push changes
   back from Profilarr's own editor; not required just to pull and sync.
5. Conflict Strategy / Sync Strategy / Auto Pull: pick to taste (`Override` +
   hourly `Auto Pull` mirrors how the existing `Dictionarry` database here is
   configured).

## Keeping your Arr instance clean

Linking the database makes every profile and custom format in it *available*
inside Profilarr — nothing is pushed to Sonarr/Radarr until you say so.
On the **Sync** page, each linked database has a per-profile toggle. Only
toggle on `Gantles WEB-1080p Streaming` and `Gantles WEB-2160p Streaming`.
Custom formats are pulled along with their profiles, so only the ~212 CFs
those two profiles actually reference reach your Arr instance — not the rest
of the German catalog.

## Pulling upstream changes

```bash
# 1. Get upstream's latest commits (doesn't touch your files yet)
git fetch trash-pcd

# 2. Merge into v2 -- should be conflict-free, since your only content
#    lives in tweaks/ and scripts/, never in ops/
git checkout v2
git merge trash-pcd/german

# 3. Rebuild + validate: catches anything upstream renamed or removed that
#    tweaks/gantles-migration.sql still references by the old name
python3 scripts/validate-migration.py

# 4. If it flags a dangling reference, fix the name in tweaks/, regenerate
#    migration-report.md, then commit
python3 scripts/generate-migration-report.py
git add tweaks/ migration-report.md
git commit -m "Fix drift: <old name> renamed to <new name> upstream"

# 5. Push to your own fork
git push origin v2
```

Once `origin`'s `v2` branch is linked in Profilarr with Auto Pull enabled,
step 5 is all that's needed on the git side — Profilarr picks up the change
on its own sync schedule. There's no fixed cadence for running this; do it
whenever you want upstream's fixes, or notice something's changed.

### Why validation can catch real bugs

Every reference in `tweaks/gantles-migration.sql` is a plain foreign key by
name (`custom_format_name` string), not an ID — if upstream renames or
deletes a custom format your tweak still calls by its old name, nothing
enforces that at the SQL-authoring level until something actually tries to
build the database. This has already happened once: the original migration
referenced `German DL`, `HDR`, `x266`, and `NOT: IMAX Enhanced`, all of which
had been renamed upstream (to `German DL (Language)`, `HDR10`, `x266
(Codec)`, and `IMAX Enhanced` respectively) before this migration was
written. `validate-migration.py` caught all four as dangling references;
they're fixed in the current file. The same class of bug is exactly what
future upstream pulls can reintroduce — hence step 3 above.

## A caveat about `validate-migration.py`

`ops/30.delete-duplicate-regex.sql` and `ops/66.fix-black-and-white-edition-cfs.sql`
fail with `UNIQUE constraint failed: condition_patterns.custom_format_name,
condition_patterns.condition_name` when replayed by this repo's validator —
**but this is a false positive of the validator, not a real bug.** Confirmed
against the actual linked Profilarr instance: both commits (`bc95b82 Delete
Duplicate Regex` and `65df316 Fix Black and White Edition CFs`) show status
`Installed` in the database's Updates log, meaning Profilarr's real compiler
applied them without issue.

The discrepancy is expected: `validate-migration.py` replays every `ops/`
file fresh, in one pass, via the plain `sqlite3` CLI. Profilarr's real
compiler applies each op incrementally as it's published, replaying value
guards, conflict detection, and op-level state that a raw one-shot SQL
replay doesn't reproduce. So this validator is a *useful smoke test* for
`tweaks/gantles-migration.sql` itself (it's what caught the 4 real stale-name
bugs), but a red flag from it about `ops/` files that predate this fork is
worth double-checking against the linked instance's Updates log before
treating it as a genuine issue.

## Verifying against the real source

`tweaks/gantles-migration.sql` has been diffed programmatically against the
actual v1 source (`profiles/Gantles WEB-1080p Streaming.yml` and
`profiles/Gantles WEB-2160p Streaming.yml` on this repo's `main` branch): all
255 custom-format score rows match exactly once mapped through the
documented v1→v2 name changes, as do both profiles' tags, upgrade settings,
quality groups, and language setting. If you ever need to re-verify after a
manual edit, diff the relevant `INSERT INTO quality_profile_custom_formats`
rows in `tweaks/gantles-migration.sql` against the YAML on `main` the same
way.

Also confirmed live: `origin`'s `v2` branch linked into a running Profilarr
instance, commit `2cedc48` shows `Installed`, and both profiles' General and
Scoring pages match the source exactly — including the one arr-specific
asymmetry (`HD Bluray Tier 03` scored for Radarr only, absent from Sonarr).
