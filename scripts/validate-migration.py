#!/usr/bin/env python3
"""
validate-migration.py
---------------------
Validates the Gantles v1 → v2 migration (tweaks/gantles-migration.sql)
against the same layer order Profilarr itself compiles in:
schema -> base (ops/) -> tweaks (tweaks/).

Steps:
  1. Build a fresh SQLite DB from schema, then ops/, then tweaks/, in that
     order, each in numeric/alphabetic order within its layer.
  2. Verify no dangling custom_format_name references in
     quality_profile_custom_formats (every CF must exist in custom_formats).
  3. Verify arr_type values are legal ('radarr', 'sonarr', 'all').
  4. Verify quality profile existence and basic settings.
  5. Verify quality groups / members are correctly wired.
  6. Report a score table for manual cross-check against v1 source YAMLs.

Usage:
  python3 scripts/validate-migration.py
  python3 scripts/validate-migration.py --db /path/to/output.db  # keep the DB
"""
import argparse
import os
import sqlite3
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPS_DIR = os.path.join(ROOT, 'ops')
TWEAKS_DIR = os.path.join(ROOT, 'tweaks')
SCHEMA_DIR = os.path.join(ROOT, 'scripts', 'schema')

PROFILES = ['Gantles WEB-1080p Streaming', 'Gantles WEB-2160p Streaming']

# Expected profile settings
EXPECTED_PROFILE_SETTINGS = {
    'Gantles WEB-1080p Streaming': {
        'upgrades_allowed': 1,
        'minimum_custom_format_score': -15000,
        'upgrade_until_score': 35000,
        'upgrade_score_increment': 1,
    },
    'Gantles WEB-2160p Streaming': {
        'upgrades_allowed': 1,
        'minimum_custom_format_score': -15000,
        'upgrade_until_score': 35000,
        'upgrade_score_increment': 1,
    },
}

# Expected quality groups per profile
EXPECTED_QUALITY_GROUPS = {
    'Gantles WEB-1080p Streaming': {
        'WEB 1080p': ['WEBRip-1080p', 'WEBDL-1080p'],
    },
    'Gantles WEB-2160p Streaming': {
        'WEB 2160p': ['WEBRip-2160p', 'WEBDL-2160p'],
        'WEB 1080p (fallback)': ['WEBRip-1080p', 'WEBDL-1080p'],
    },
}

# New CFs introduced by this migration (must exist after applying ops)
MIGRATION_NEW_CFS = [
    '10bit', 'Opus', 'MP3', 'HLG',
    'German Subbed', 'Language: Not English',
    'Language: Not Original', 'Hardcoded Subs',
]


def sort_key(name):
    try:
        return int(name.split('.')[0])
    except ValueError:
        return 9_999_999


def build_db(db_path):
    """Apply the vendored base schema, then all ops, to a fresh DB;
    return list of (filename, error_msg) for failures."""
    if os.path.exists(db_path):
        os.remove(db_path)

    failures = []

    # This repo only holds data migrations; the tables themselves come from
    # Profilarr's own schema (github.com/Dictionarry-Hub/schema, ops/),
    # vendored under scripts/schema/.
    schema_files = sorted([f for f in os.listdir(SCHEMA_DIR) if f.endswith('.sql')], key=sort_key)
    for f in schema_files:
        path = os.path.join(SCHEMA_DIR, f)
        with open(path, 'r', encoding='utf-8') as fh:
            sql = fh.read()
        result = subprocess.run(
            ['sqlite3', db_path],
            input=sql,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 or result.stderr.strip():
            failures.append((f'schema/{f}', result.stderr.strip()))
    if failures:
        return failures

    files = sorted([f for f in os.listdir(OPS_DIR) if f.endswith('.sql')], key=sort_key)
    for f in files:
        path = os.path.join(OPS_DIR, f)
        with open(path, 'r', encoding='utf-8') as fh:
            sql = fh.read()
        result = subprocess.run(
            ['sqlite3', db_path],
            input=sql,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 or result.stderr.strip():
            failures.append((f, result.stderr.strip()))
    # Note: unlike the schema layer, an ops-layer failure isn't fatal to the
    # build -- sqlite3 keeps executing subsequent statements/files in the same
    # session (matching how a single bad statement doesn't abort a real
    # Profilarr compile either), so tweaks still get a chance to apply and get
    # checked even if an upstream op has a pre-existing bug (see ops/30, ops/66).

    # Tweaks layer: applied after all base ops, same as Profilarr's real
    # compile order (schema -> base -> tweaks -> user).
    tweak_files = sorted([f for f in os.listdir(TWEAKS_DIR) if f.endswith('.sql')])
    for f in tweak_files:
        path = os.path.join(TWEAKS_DIR, f)
        with open(path, 'r', encoding='utf-8') as fh:
            sql = fh.read()
        result = subprocess.run(
            ['sqlite3', db_path],
            input=sql,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 or result.stderr.strip():
            failures.append((f'tweaks/{f}', result.stderr.strip()))
    return failures


def check_dangling_cf_refs(conn):
    """Every CF name in quality_profile_custom_formats must exist in custom_formats."""
    rows = conn.execute("""
        SELECT DISTINCT qpcf.quality_profile_name, qpcf.custom_format_name
        FROM quality_profile_custom_formats qpcf
        LEFT JOIN custom_formats cf ON cf.name = qpcf.custom_format_name
        WHERE cf.name IS NULL
        ORDER BY qpcf.quality_profile_name, qpcf.custom_format_name
    """).fetchall()
    return rows  # list of (profile_name, cf_name)


def check_arr_types(conn):
    """arr_type must be one of 'radarr', 'sonarr', 'all'."""
    rows = conn.execute("""
        SELECT DISTINCT arr_type
        FROM quality_profile_custom_formats
        WHERE arr_type NOT IN ('radarr', 'sonarr', 'all')
    """).fetchall()
    return [r[0] for r in rows]


def check_profile_settings(conn):
    """Check upgrade settings match expected values."""
    issues = []
    for profile, expected in EXPECTED_PROFILE_SETTINGS.items():
        row = conn.execute("""
            SELECT upgrades_allowed, minimum_custom_format_score,
                   upgrade_until_score, upgrade_score_increment
            FROM quality_profiles WHERE name = ?
        """, (profile,)).fetchone()
        if row is None:
            issues.append(f"Profile '{profile}' NOT FOUND in quality_profiles")
            continue
        actual = {
            'upgrades_allowed': row[0],
            'minimum_custom_format_score': row[1],
            'upgrade_until_score': row[2],
            'upgrade_score_increment': row[3],
        }
        for key, val in expected.items():
            if actual[key] != val:
                issues.append(
                    f"Profile '{profile}' {key}: expected {val}, got {actual[key]}"
                )
    return issues


def check_quality_groups(conn):
    """Verify quality groups and their members."""
    issues = []
    for profile, groups in EXPECTED_QUALITY_GROUPS.items():
        for group_name, expected_members in groups.items():
            row = conn.execute("""
                SELECT name FROM quality_groups
                WHERE quality_profile_name = ? AND name = ?
            """, (profile, group_name)).fetchone()
            if row is None:
                issues.append(f"Quality group '{group_name}' missing for '{profile}'")
                continue
            actual_members = [r[0] for r in conn.execute("""
                SELECT quality_name FROM quality_group_members
                WHERE quality_profile_name = ? AND quality_group_name = ?
                ORDER BY position
            """, (profile, group_name)).fetchall()]
            if set(actual_members) != set(expected_members):
                issues.append(
                    f"Group '{group_name}' ({profile}) members mismatch: "
                    f"expected {expected_members}, got {actual_members}"
                )
    return issues


def check_new_cfs(conn):
    """All 8 new CFs must exist in custom_formats."""
    missing = []
    for cf in MIGRATION_NEW_CFS:
        row = conn.execute("SELECT name FROM custom_formats WHERE name = ?", (cf,)).fetchone()
        if row is None:
            missing.append(cf)
    return missing


def print_score_table(conn, profile):
    """Print all CF scores for a profile, grouped by arr_type."""
    print(f"\n  === {profile} ===")
    for arr_type in ('sonarr', 'radarr'):
        rows = conn.execute("""
            SELECT custom_format_name, score
            FROM quality_profile_custom_formats
            WHERE quality_profile_name = ? AND arr_type = ?
            ORDER BY score DESC
        """, (profile, arr_type)).fetchall()
        if rows:
            print(f"\n  [{arr_type.upper()}]  ({len(rows)} entries)")
            for cf_name, score in rows:
                print(f"    {score:>8}  {cf_name}")


def main():
    parser = argparse.ArgumentParser(description='Validate Gantles migration ops.')
    parser.add_argument('--db', default=None,
                        help='Path to keep the test DB (default: temp file, deleted after)')
    parser.add_argument('--scores', action='store_true',
                        help='Print full score tables for both profiles')
    args = parser.parse_args()

    if args.db:
        db_path = args.db
        keep_db = True
    else:
        tmp = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
        db_path = tmp.name
        tmp.close()
        keep_db = False

    print(f"Building database at {db_path} ...")
    failures = build_db(db_path)

    errors = 0

    if failures:
        print(f"\n[FAIL] {len(failures)} op(s) failed to apply:")
        for fname, err in failures:
            print(f"  {fname}:\n    {err}")
        errors += len(failures)
    else:
        print("[OK]  All ops applied without errors.")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    # --- Dangling CF references ---
    dangling = check_dangling_cf_refs(conn)
    if dangling:
        print(f"\n[FAIL] {len(dangling)} dangling custom_format_name reference(s):")
        for profile_name, cf_name in dangling:
            print(f"  Profile '{profile_name}': CF '{cf_name}' not in custom_formats")
        errors += len(dangling)
    else:
        print("[OK]  No dangling custom_format_name references.")

    # --- arr_type validity ---
    bad_types = check_arr_types(conn)
    if bad_types:
        print(f"\n[FAIL] Illegal arr_type value(s): {bad_types}")
        errors += len(bad_types)
    else:
        print("[OK]  All arr_type values are valid.")

    # --- Profile settings ---
    settings_issues = check_profile_settings(conn)
    if settings_issues:
        print(f"\n[FAIL] Profile settings mismatch ({len(settings_issues)}):")
        for issue in settings_issues:
            print(f"  {issue}")
        errors += len(settings_issues)
    else:
        print("[OK]  Profile settings match expected values.")

    # --- Quality groups ---
    group_issues = check_quality_groups(conn)
    if group_issues:
        print(f"\n[FAIL] Quality group issues ({len(group_issues)}):")
        for issue in group_issues:
            print(f"  {issue}")
        errors += len(group_issues)
    else:
        print("[OK]  Quality groups and members are correctly wired.")

    # --- New CFs ---
    missing_cfs = check_new_cfs(conn)
    if missing_cfs:
        print(f"\n[FAIL] New CFs not found in custom_formats: {missing_cfs}")
        errors += len(missing_cfs)
    else:
        print(f"[OK]  All {len(MIGRATION_NEW_CFS)} new custom formats present.")

    # --- Score counts ---
    for profile in PROFILES:
        count = conn.execute("""
            SELECT COUNT(*) FROM quality_profile_custom_formats
            WHERE quality_profile_name = ?
        """, (profile,)).fetchone()[0]
        print(f"[INFO] '{profile}': {count} CF score entries total.")

    if args.scores:
        print("\n--- Full score tables ---")
        for profile in PROFILES:
            print_score_table(conn, profile)

    conn.close()

    if not keep_db:
        os.remove(db_path)

    print(f"\n{'='*60}")
    if errors == 0:
        print("VALIDATION PASSED — migration looks good.")
    else:
        print(f"VALIDATION FAILED — {errors} error(s) found.")
    print('='*60)

    sys.exit(0 if errors == 0 else 1)


if __name__ == '__main__':
    main()
