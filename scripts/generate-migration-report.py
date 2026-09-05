#!/usr/bin/env python3
"""
Regenerate migration-report.md from tweaks/gantles-migration.sql.

Run this after any manual edit to tweaks/gantles-migration.sql (e.g. fixing
a name that upstream renamed) so the report stays in sync with the SQL.
Usage: python3 scripts/generate-migration-report.py
"""
import os
import re
from collections import OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "tweaks", "gantles-migration.sql")

# v1 (source) name -> v2 (canonical upstream) name, for CFs whose name changed
# during the port. Everything not listed here is unchanged (v1 name == v2 name).
RENAMES = {
    "Repack&Proper": "Repack/Proper",
    "Line&Mic Dubbed": "Line/Mic Dubbed",
    "DV (w&o HDR ...)": "DV (w/o HDR fallback)",
    "HDR10+ Boost": "HDR10Plus Boost",
    "IMAX Enhanced": "IMAX Enhanced",  # name text unchanged; upstream identity changed (see note)
}
# reverse lookup by v2 name -> v1 name, built from the mapping table plus
# the special-cased ones that need clarifying notes rather than a simple pair.
V2_TO_V1 = {v: k for k, v in RENAMES.items()}

# CFs that had to be corrected during validation because ops/71 originally
# referenced a stale pre-rename upstream name (fixed in this same session).
CORRECTED_DURING_VALIDATION = {
    "German DL (Language)": "German DL",
    "HDR10": "HDR",
    "x266 (Codec)": "x266",
    "IMAX Enhanced": "NOT: IMAX Enhanced",
}

NEW_CFS = {
    "10bit", "Opus", "MP3", "HLG", "German Subbed",
    "Language: Not English", "Language: Not Original", "Hardcoded Subs",
}

with open(PATH) as f:
    content = f.read()

pattern = re.compile(
    r"INSERT INTO quality_profile_custom_formats "
    r"\(quality_profile_name, custom_format_name, arr_type, score\) VALUES \("
    r"'([^']*)', '([^']*)', '([^']*)', (-?\d+)\);"
)

rows = []
for m in pattern.finditer(content):
    profile, cf_name, arr_type, score = m.groups()
    rows.append((profile, cf_name, arr_type, int(score)))

print(f"Parsed {len(rows)} score rows")

def source_name(cf_name):
    if cf_name in CORRECTED_DURING_VALIDATION:
        return CORRECTED_DURING_VALIDATION[cf_name]
    if cf_name in V2_TO_V1:
        return V2_TO_V1[cf_name]
    return cf_name

def status(cf_name):
    if cf_name in NEW_CFS:
        return "NEW (created in v2)"
    if cf_name in CORRECTED_DURING_VALIDATION:
        return "renamed upstream — corrected during validation"
    if cf_name in V2_TO_V1:
        return "renamed (v1 name → v2 canonical name)"
    return "unchanged"

# Build markdown grouped by profile
by_profile = OrderedDict()
for profile, cf_name, arr_type, score in rows:
    by_profile.setdefault(profile, []).append((cf_name, arr_type, score))

lines = []
lines.append("# Gantles v1 → v2 Migration Report\n")
lines.append(
    "Source: `tweaks/gantles-migration.sql`. Every score below is preserved "
    "**exactly** from the v1 YAML source — this migration ports custom format "
    "names and profile structure to the v2 (PCD/SQL) schema, it does not "
    "re-tune any scores.\n"
)
lines.append(
    "Columns: **Source CF** (v1 YAML name) → **v2 CF** (name as stored in "
    "`custom_formats` after this migration) → **Arr** → **Score** (old = new, "
    "unchanged) → **Status**.\n"
)
lines.append(
    "> Four rows originally referenced a name that had already been renamed "
    "upstream by a later, unrelated op (30–66 have no bearing on this — the "
    "renames happened in ops 27, 44, 51, all committed to the `german` branch "
    "before this migration was written). `scripts/validate-migration.py` "
    "caught these as dangling `custom_format_name` references against a "
    "freshly built database, and they were corrected before this report was "
    "generated. See the **Status** column.\n"
)

total_new = 0
total_renamed = 0
total_corrected = 0
total_unchanged = 0

for profile, entries in by_profile.items():
    lines.append(f"\n## {profile}\n")
    lines.append("| Source CF (v1) | v2 CF | Arr | Score | Status |")
    lines.append("|---|---|---|---|---|")
    # stable order: as they appear in the file, sonarr block then radarr block
    for cf_name, arr_type, score in entries:
        src = source_name(cf_name)
        st = status(cf_name)
        if st.startswith("NEW"):
            total_new += 1
        elif st.startswith("renamed upstream"):
            total_corrected += 1
        elif st.startswith("renamed"):
            total_renamed += 1
        else:
            total_unchanged += 1
        src_display = src if src != cf_name else "*(same)*"
        lines.append(f"| {src_display} | {cf_name} | {arr_type} | {score} | {st} |")

lines.append("\n## Summary\n")
lines.append(f"- Total score entries: {len(rows)}")
lines.append(f"- Unchanged name (v1 == v2): {total_unchanged}")
lines.append(f"- Renamed (documented v1 → v2 canonical mapping): {total_renamed}")
lines.append(f"- Renamed upstream, corrected during validation: {total_corrected}")
lines.append(f"- Brand-new custom formats created by this migration: {total_new}")
lines.append(
    f"\nNew custom formats (created in Part 2 of the migration): "
    + ", ".join(f"`{c}`" for c in sorted(NEW_CFS))
)

out_path = os.path.join(ROOT, "migration-report.md")
with open(out_path, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"Wrote {out_path}")
print(f"new={total_new} renamed={total_renamed} corrected={total_corrected} unchanged={total_unchanged}")
