#!/usr/bin/env python3
"""
Build a test SQLite database the same way Profilarr compiles a linked PCD:
schema -> ops/*.sql (base, numeric order) -> tweaks/*.sql (alphabetic order).
Usage: python3 scripts/build-test-db.py [output.db]
"""
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCHEMA_DIR = os.path.join(SCRIPT_DIR, 'schema')
ops_dir = os.path.join(SCRIPT_DIR, '..', 'ops')
tweaks_dir = os.path.join(SCRIPT_DIR, '..', 'tweaks')
db_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/profilarr-test.db'

if os.path.exists(db_path):
    os.remove(db_path)

def sort_key(name):
    try:
        return int(name.split('.')[0])
    except ValueError:
        return 9999999

# This repo only holds data migrations; the tables themselves come from
# Profilarr's own schema (github.com/Dictionarry-Hub/schema, ops/), vendored
# under scripts/schema/. Apply that first so the data ops have somewhere to land.
schema_files = sorted(os.listdir(SCHEMA_DIR), key=sort_key)
for f in schema_files:
    if not f.endswith('.sql'):
        continue
    path = os.path.join(SCHEMA_DIR, f)
    with open(path, 'r') as fh:
        sql = fh.read()
    r = subprocess.run(['sqlite3', db_path], input=sql, capture_output=True, text=True)
    if r.returncode != 0 or r.stderr.strip():
        print(f'FAIL [schema/{f}]: {r.stderr.strip()}')
        sys.exit(1)
    print(f'OK   schema/{f}')

files = sorted(os.listdir(ops_dir), key=sort_key)
errors = []

for f in files:
    if not f.endswith('.sql'):
        continue
    path = os.path.join(ops_dir, f)
    with open(path, 'r') as fh:
        sql = fh.read()
    r = subprocess.run(['sqlite3', db_path], input=sql, capture_output=True, text=True)
    if r.returncode != 0 or r.stderr.strip():
        errors.append((f, r.stderr.strip()))
        print(f'FAIL [{f}]: {r.stderr.strip()}')
    else:
        print(f'OK   {f}')

# Note: unlike a schema failure, an ops-layer failure isn't fatal to the
# build -- sqlite3 keeps executing subsequent statements/files in the same
# session, so tweaks still get applied and can be inspected even when an
# upstream op has a pre-existing bug (see ops/30, ops/66).
tweak_files = sorted(f for f in os.listdir(tweaks_dir) if f.endswith('.sql'))
for f in tweak_files:
    path = os.path.join(tweaks_dir, f)
    with open(path, 'r') as fh:
        sql = fh.read()
    r = subprocess.run(['sqlite3', db_path], input=sql, capture_output=True, text=True)
    if r.returncode != 0 or r.stderr.strip():
        errors.append((f'tweaks/{f}', r.stderr.strip()))
        print(f'FAIL [tweaks/{f}]: {r.stderr.strip()}')
    else:
        print(f'OK   tweaks/{f}')

if errors:
    print(f'\n{len(errors)} op(s)/tweak(s) FAILED.')
    sys.exit(1)
else:
    print(f'\nAll {len(files)} ops + {len(tweak_files)} tweak(s) applied to {db_path} successfully.')
