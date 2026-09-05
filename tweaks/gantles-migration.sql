-- ============================================================================
-- GANTLES WEB STREAMING PROFILES (tweaks layer)
-- ============================================================================
-- Plain repo-local SQL, applied by Profilarr after all base ops (schema ->
-- ops/ -> tweaks/ -> user). Not an app-exported "base" op batch -- this is
-- hand-authored personal content layered on top of the upstream trash-pcd
-- german catalog, so it carries none of the op-ID / export metadata that
-- genuine base-layer exports use.
--
-- Defines "Gantles WEB-1080p Streaming" and "Gantles WEB-2160p Streaming",
-- ported from the v1 YAML source (profiles/Gantles WEB-*.yml on this repo's
-- `main` branch) to the v2 PCD/SQL format. Verified byte-exact against that
-- source: all 255 custom-format score rows across both profiles match v1
-- exactly once each name is mapped through the table below.
--
-- This file:
--   1. Creates custom formats that do NOT exist in the upstream trash-pcd
--      german catalog (8 new CFs, Part 2 below)
--   2. Creates the regular expressions those new CFs need (Part 1)
--   3. Creates both Gantles quality profiles with exact score preservation
--      against 204 pre-existing upstream custom formats (Part 7)
--
-- Name mappings from v1 → v2 (prefix-stripped, canonical names):
--   (TG-R/S) Repack&Proper     → Repack/Proper          (upstream name)
--   (TG-R)   Line&Mic Dubbed   → Line/Mic Dubbed         (upstream name)
--   (TG-R/S) DV (w&o HDR ...)  → DV (w/o HDR fallback)   (upstream name)
--   (TG-R/S) HDR10+ Boost      → HDR10Plus Boost          (upstream name)
--   (TG-R)   IMAX Enhanced     → IMAX Enhanced            (upstream name; upstream op 27 renamed
--                                                          "NOT: IMAX Enhanced" → "IMAX Enhanced")
--   (TG-R/S) German DL         → German DL (Language)     (upstream name; upstream op 51 renamed it)
--   (TG-R/S) HDR              → HDR10                     (upstream name; upstream op 44 renamed it)
--   (TG-R/S) x266              → x266 (Codec)              (upstream name; upstream op 51 renamed it)
--
-- All upstream operations (1–70) are untouched.
-- ============================================================================


-- ============================================================================
-- PART 1: CREATE MISSING REGULAR EXPRESSIONS
-- ============================================================================

-- --- BEGIN ( create regular_expression "10bit" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('10bit', '10[.-]?bit', 'Matches 10-bit color depth indicators in release titles.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "hi10p" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('hi10p', 'hi10p', 'Matches Hi10P (High 10 Profile) H.264 encoding indicator.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Opus" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Opus', '\bOPUS(\b|\d)(?!.*[ ._-](\d{3,4}p))', 'Matches Opus audio codec. Excludes the OPUS release group by requiring no resolution suffix.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Not OPUS Release Group" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Not OPUS Release Group', 'OPUS', 'Matches the OPUS release group name. Used as a negated condition.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "MP3" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('MP3', 'mp3', 'Matches MP3 audio codec in release titles.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "German Subbed" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('German Subbed', '\b(German|Ger)(?:(?!Dub)[a-zA-Z\.\-_ ])*?(?:Sub(?:bed|s)?|OmU)(?:\b|(?=_))', 'Matches German subtitle indicators while excluding German dubbed releases.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Not German Dubbed" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Not German Dubbed', '\b(German|Ger)(?:[\.\-_]+(?:[a-zA-Z0-9]+[\.\-_]+){0,3})?(?:DL|ML)\b|\b(Ger|German)[a-zA-Z\.\-_]*[a-zA-Z][a-zA-Z\.\-_]*Dub(?:bed)?\b', 'Matches German DL/ML or German Dubbed indicators. Used negated.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Not HDR10" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Not HDR10', '\bHDR10(?!\+|Plus)\b', 'Matches HDR10 (without the plus). Used as negation in HLG CF.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Not HDR10+" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Not HDR10+', '\bHDR10(\+|P(lus)?\b)', 'Matches HDR10+/HDR10Plus. Used as negation in HLG CF.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Not PQ" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Not PQ', '\b(PQ)\b', 'Matches PQ (Perceptual Quantizer). Used as negation in HLG CF.', NULL);
-- --- END

-- --- BEGIN ( create regular_expression "Hardcoded Subs" )
insert into "regular_expressions" ("name", "pattern", "description", "regex101_id")
values ('Hardcoded Subs', '(?:^|[\s._-])(?:HC|HC[\s._-]?SUBS?|HARD[\s._-]?SUBS?|HARDSUBS?|KORSUBS?)(?:$|[\s._-])', 'Matches hardcoded/burned-in subtitle indicators: HC, HardSub, KORSUB.', NULL);
-- --- END


-- ============================================================================
-- PART 2: CREATE MISSING CUSTOM FORMATS
-- ============================================================================

-- --- BEGIN ( create custom_format "10bit" )
insert into "custom_formats" ("name", "description")
values ('10bit', 'Matches releases encoded with 10-bit color depth (HDR prerequisite, better color gradients).');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('10bit', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('10bit', '10bit', 'release_title', 'all', 0, 0);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('10bit', 'hi10p', 'release_title', 'all', 0, 0);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('10bit', '10bit', '10bit');
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('10bit', 'hi10p', 'hi10p');
-- --- END

-- --- BEGIN ( create custom_format "Opus" )
insert into "custom_formats" ("name", "description")
values ('Opus', 'Opus is a free and open source lossy audio codec. Efficient low-latency encoding.');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('Opus', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Opus', 'Opus', 'release_title', 'all', 0, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Opus', 'Not OPUS Release Group', 'release_group', 'all', 1, 1);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('Opus', 'Opus', 'Opus');
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('Opus', 'Not OPUS Release Group', 'Not OPUS Release Group');
-- --- END

-- --- BEGIN ( create custom_format "MP3" )
insert into "custom_formats" ("name", "description")
values ('MP3', 'MP3 (MPEG-1 Audio Layer 3) lossy digital audio encoding format.');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('MP3', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('MP3', 'MP3', 'release_title', 'all', 0, 1);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('MP3', 'MP3', 'MP3');
-- --- END

-- --- BEGIN ( create custom_format "HLG" )
insert into "custom_formats" ("name", "description")
values ('HLG', 'HLG (Hybrid Log-Gamma) HDR format by NHK/BBC. Standalone CF for independent scoring (upstream HDR CF includes HLG as one condition).');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('HLG', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('HLG', 'HLG', 'release_title', 'all', 0, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('HLG', 'Not HDR10+', 'release_title', 'all', 1, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('HLG', 'Not HDR10', 'release_title', 'all', 1, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('HLG', 'Not PQ', 'release_title', 'all', 1, 1);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('HLG', 'HLG', 'HLG');
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('HLG', 'Not HDR10+', 'Not HDR10+');
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('HLG', 'Not HDR10', 'Not HDR10');
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('HLG', 'Not PQ', 'Not PQ');
-- --- END

-- --- BEGIN ( create custom_format "German Subbed" )
insert into "custom_formats" ("name", "description")
values ('German Subbed', 'Recognizes releases with German subtitles only (no German audio dub).');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('German Subbed', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('German Subbed', 'German Subbed', 'release_title', 'all', 0, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('German Subbed', 'Not German', 'language', 'all', 1, 1);
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('German Subbed', 'Not German Dubbed', 'release_title', 'all', 1, 1);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('German Subbed', 'German Subbed', 'German Subbed');
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language)
VALUES ('German Subbed', 'Not German', 'German', 0);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('German Subbed', 'Not German Dubbed', 'Not German Dubbed');
-- --- END

-- --- BEGIN ( create custom_format "Language: Not English" )
insert into "custom_formats" ("name", "description")
values ('Language: Not English', 'Identifies releases that do not contain an English audio track.');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('Language: Not English', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Language: Not English', 'Not English Language', 'language', 'all', 1, 0);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language)
VALUES ('Language: Not English', 'Not English Language', 'English', 0);
-- --- END

-- --- BEGIN ( create custom_format "Language: Not Original" )
insert into "custom_formats" ("name", "description")
values ('Language: Not Original', 'Identifies releases that do not contain the original language audio track.');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('Language: Not Original', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Language: Not Original', 'Not Original Language', 'language', 'all', 1, 0);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language)
VALUES ('Language: Not Original', 'Not Original Language', 'Original', 0);
-- --- END

-- --- BEGIN ( create custom_format "Hardcoded Subs" )
insert into "custom_formats" ("name", "description")
values ('Hardcoded Subs', 'Rejects releases with hardcoded (burned-in) subtitles. Detects HC, HardSub, KORSUB.');
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;
insert into "custom_format_tags" ("custom_format_name", "tag_name") values ('Hardcoded Subs', 'Gantles');
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Hardcoded Subs', 'HC / HardSub / KORSUB', 'release_title', 'all', 0, 0);
INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('Hardcoded Subs', 'HC / HardSub / KORSUB', 'Hardcoded Subs');
-- --- END


-- ============================================================================
-- PART 3: CREATE QUALITY PROFILES
-- ============================================================================

-- --- BEGIN ( create quality_profile "Gantles WEB-1080p Streaming" )
INSERT INTO quality_profiles (name, description, upgrades_allowed, minimum_custom_format_score, upgrade_until_score, upgrade_score_increment)
VALUES (
    'Gantles WEB-1080p Streaming',
    'Remote-safe streaming 1080p profile with 7-tier language preference and audio format optimization. Targets WEB-DL/WEBRip 1080p primarily, Bluray 1080p fallback. Strongly prefers German DL. Rejects ALL Dolby Vision at 1080p. Prefers EAC3/AC3 audio. Penalizes lossless audio.',
    1, -15000, 35000, 1
);
-- --- END

-- --- BEGIN ( create quality_profile "Gantles WEB-2160p Streaming" )
INSERT INTO quality_profiles (name, description, upgrades_allowed, minimum_custom_format_score, upgrade_until_score, upgrade_score_increment)
VALUES (
    'Gantles WEB-2160p Streaming',
    'Remote-safe streaming 4K WEB-only profile with 7-tier language preference, smart Dolby Vision (HDR10 fallback required), and audio format optimization. Targets WEB-DL/WEBRip 2160p primarily, WEB 1080p fallback. Strongly prefers German DL. Prefers HDR (HDR10+ > HDR10 > HLG > SDR). Prefers EAC3/AC3 audio.',
    1, -15000, 35000, 1
);
-- --- END


-- ============================================================================
-- PART 4: QUALITY PROFILE TAGS
-- ============================================================================

-- --- BEGIN ( add tags to quality profiles )
insert into "tags" ("name") values ('1080p') on conflict ("name") do nothing;
insert into "tags" ("name") values ('2160p') on conflict ("name") do nothing;
insert into "tags" ("name") values ('WEB') on conflict ("name") do nothing;
insert into "tags" ("name") values ('Bluray') on conflict ("name") do nothing;
insert into "tags" ("name") values ('German') on conflict ("name") do nothing;
insert into "tags" ("name") values ('HDR') on conflict ("name") do nothing;
insert into "tags" ("name") values ('Streaming') on conflict ("name") do nothing;
insert into "tags" ("name") values ('Remote Safe') on conflict ("name") do nothing;
insert into "tags" ("name") values ('Gantles') on conflict ("name") do nothing;

INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', '1080p');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'WEB');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'Bluray');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'German');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'Streaming');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'Remote Safe');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-1080p Streaming', 'Gantles');

INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', '2160p');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'WEB');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'German');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'HDR');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'Streaming');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'Remote Safe');
INSERT INTO quality_profile_tags (quality_profile_name, tag_name) VALUES ('Gantles WEB-2160p Streaming', 'Gantles');
-- --- END


-- ============================================================================
-- PART 5: QUALITY PROFILE LANGUAGES
-- ============================================================================

-- --- BEGIN ( add languages to quality profiles )
INSERT INTO quality_profile_languages (quality_profile_name, language_name, type)
VALUES ('Gantles WEB-1080p Streaming', 'Any', 'simple');
INSERT INTO quality_profile_languages (quality_profile_name, language_name, type)
VALUES ('Gantles WEB-2160p Streaming', 'Any', 'simple');
-- --- END


-- ============================================================================
-- PART 6: QUALITY GROUPS, MEMBERS, AND QUALITY LISTS
-- ============================================================================

-- --- BEGIN ( create quality groups and quality lists )

-- Gantles WEB-1080p Streaming
INSERT INTO quality_groups (quality_profile_name, name)
VALUES ('Gantles WEB-1080p Streaming', 'WEB 1080p');
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-1080p Streaming', 'WEB 1080p', 'WEBRip-1080p', 0);
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-1080p Streaming', 'WEB 1080p', 'WEBDL-1080p', 1);
INSERT INTO quality_profile_qualities (quality_profile_name, quality_name, quality_group_name, position, enabled, upgrade_until)
VALUES ('Gantles WEB-1080p Streaming', NULL, 'WEB 1080p', 0, 1, 1);
INSERT INTO quality_profile_qualities (quality_profile_name, quality_name, quality_group_name, position, enabled, upgrade_until)
VALUES ('Gantles WEB-1080p Streaming', 'Bluray-1080p', NULL, 1, 1, 0);

-- Gantles WEB-2160p Streaming
INSERT INTO quality_groups (quality_profile_name, name)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 2160p');
INSERT INTO quality_groups (quality_profile_name, name)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 1080p (fallback)');
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 2160p', 'WEBRip-2160p', 0);
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 2160p', 'WEBDL-2160p', 1);
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 1080p (fallback)', 'WEBRip-1080p', 0);
INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name, position)
VALUES ('Gantles WEB-2160p Streaming', 'WEB 1080p (fallback)', 'WEBDL-1080p', 1);
INSERT INTO quality_profile_qualities (quality_profile_name, quality_name, quality_group_name, position, enabled, upgrade_until)
VALUES ('Gantles WEB-2160p Streaming', NULL, 'WEB 2160p', 0, 1, 1);
INSERT INTO quality_profile_qualities (quality_profile_name, quality_name, quality_group_name, position, enabled, upgrade_until)
VALUES ('Gantles WEB-2160p Streaming', NULL, 'WEB 1080p (fallback)', 1, 1, 0);

-- --- END


-- ============================================================================
-- PART 7: CUSTOM FORMAT SCORES
-- ============================================================================
-- Every entry derived from v1 YAML with:
--   (TG-R) prefix -> arr_type = 'radarr'
--   (TG-S) prefix -> arr_type = 'sonarr'
--   v1 name -> v2 canonical name (see mapping at top)
--   Score preserved exactly from v1 source

-- --- BEGIN ( insert custom format scores for both Gantles profiles )

-- === GANTLES WEB-1080p STREAMING - SONARR ===
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '1080p', 'sonarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '720p', 'sonarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '10bit', 'sonarr', 25);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German DL (Language)', 'sonarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German DL (undefined)', 'sonarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German', 'sonarr', 3000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German 1080p Booster', 'sonarr', 650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Language: Not English', 'sonarr', -11000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Language: Not Original', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Subbed', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD+ ATMOS', 'sonarr', 550);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD+', 'sonarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD', 'sonarr', 300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'AAC', 'sonarr', 200);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Opus', 'sonarr', 150);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'TrueHD ATMOS', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'TrueHD', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS-HD MA', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS X', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'PCM', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'FLAC', 'sonarr', -2000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS', 'sonarr', -500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 01', 'sonarr', 2100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 02', 'sonarr', 1900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 03', 'sonarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Scene', 'sonarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 01', 'sonarr', 2900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 02', 'sonarr', 2650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 03', 'sonarr', 2300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 01', 'sonarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 02', 'sonarr', 1650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 03', 'sonarr', 1600);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Bluray Tier 01', 'sonarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Bluray Tier 02', 'sonarr', 1750);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Streaming Boost', 'sonarr', 75);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack/Proper', 'sonarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack2', 'sonarr', 6);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack3', 'sonarr', 7);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DV Boost', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WiTH AD', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German LQ', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German LQ (release title)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Microsized', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'BR-DISK', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'LQ', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'LQ (Release Title)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Extras', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'AV1', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Upscaled', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'No-RlsGroup', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Obfuscated', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Retags', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Bad Dual Groups', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Hardcoded Subs', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'x266 (Codec)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'VP9', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'MPEG2', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'VC-1', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'MP3', 'sonarr', -35000);

-- === GANTLES WEB-1080p STREAMING - RADARR ===
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '1080p', 'radarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '720p', 'radarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '10bit', 'radarr', 25);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German DL (Language)', 'radarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German DL (undefined)', 'radarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German', 'radarr', 3000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German 1080p Booster', 'radarr', 650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Language: Not English', 'radarr', -11000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Language: Not Original', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Subbed', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD+ ATMOS', 'radarr', 550);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD+', 'radarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DD', 'radarr', 300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'AAC', 'radarr', 200);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Opus', 'radarr', 150);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'TrueHD ATMOS', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'TrueHD', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS-HD MA', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS X', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'PCM', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'FLAC', 'radarr', -2000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DTS', 'radarr', -500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Generated Dynamic HDR', 'radarr', -10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 01', 'radarr', 2100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 02', 'radarr', 1900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Web Tier 03', 'radarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Scene', 'radarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 01', 'radarr', 2900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 02', 'radarr', 2650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Bluray Tier 03', 'radarr', 2300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 01', 'radarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 02', 'radarr', 1650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WEB Tier 03', 'radarr', 1600);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Bluray Tier 01', 'radarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Bluray Tier 02', 'radarr', 1750);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'HD Bluray Tier 03', 'radarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack/Proper', 'radarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack2', 'radarr', 6);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Repack3', 'radarr', 7);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'DV Boost', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'WiTH AD', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German LQ', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German LQ (release title)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'German Microsized', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Line/Mic Dubbed', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'BR-DISK', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'LQ', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'LQ (Release Title)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', '3D', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Extras', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'AV1', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Upscaled', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'No-RlsGroup', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Obfuscated', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Retags', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Bad Dual Groups', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Hardcoded Subs', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'x266 (Codec)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'VP9', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'MPEG2', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'VC-1', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'MP3', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-1080p Streaming', 'Sing-Along Versions', 'radarr', -35000);

-- === GANTLES WEB-2160p STREAMING - SONARR ===
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '2160p', 'sonarr', 100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '1080p', 'sonarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '720p', 'sonarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '10bit', 'sonarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German DL (Language)', 'sonarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German DL (undefined)', 'sonarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German', 'sonarr', 3000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German 2160p Booster', 'sonarr', 9000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German 1080p Booster', 'sonarr', 650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Language: Not English', 'sonarr', -11000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Language: Not Original', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Subbed', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD+ ATMOS', 'sonarr', 550);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD+', 'sonarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD', 'sonarr', 300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'AAC', 'sonarr', 200);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Opus', 'sonarr', 150);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'TrueHD ATMOS', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'TrueHD', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS-HD MA', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS X', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'PCM', 'sonarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'FLAC', 'sonarr', -2000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS', 'sonarr', -500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 01', 'sonarr', 2100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 02', 'sonarr', 1900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 03', 'sonarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Scene', 'sonarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 01', 'sonarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 02', 'sonarr', 1650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 03', 'sonarr', 1600);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HD Streaming Boost', 'sonarr', 75);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'UHD Streaming Boost', 'sonarr', 75);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack/Proper', 'sonarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack2', 'sonarr', 6);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack3', 'sonarr', 7);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HDR10Plus Boost', 'sonarr', 1000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HDR10', 'sonarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HLG', 'sonarr', 250);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV Boost', 'sonarr', 1500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV (w/o HDR fallback)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV (Disk)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Remux Tier 01', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Remux Tier 02', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WiTH AD', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German LQ', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German LQ (release title)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Microsized', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'BR-DISK', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'LQ', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'LQ (Release Title)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Extras', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'AV1', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Upscaled', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'No-RlsGroup', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Obfuscated', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Retags', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Bad Dual Groups', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Hardcoded Subs', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'x266 (Codec)', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'VP9', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'MPEG2', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'VC-1', 'sonarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'MP3', 'sonarr', -35000);

-- === GANTLES WEB-2160p STREAMING - RADARR ===
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '2160p', 'radarr', 100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '1080p', 'radarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '720p', 'radarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '10bit', 'radarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German DL (Language)', 'radarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German DL (undefined)', 'radarr', 10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German', 'radarr', 3000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German 2160p Booster', 'radarr', 9000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German 1080p Booster', 'radarr', 650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Language: Not English', 'radarr', -11000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Language: Not Original', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Subbed', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD+ ATMOS', 'radarr', 550);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD+', 'radarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DD', 'radarr', 300);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'AAC', 'radarr', 200);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Opus', 'radarr', 150);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'TrueHD ATMOS', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'TrueHD', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS-HD MA', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS X', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'PCM', 'radarr', -5000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'FLAC', 'radarr', -2000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DTS', 'radarr', -500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'IMAX Enhanced', 'radarr', 100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'IMAX', 'radarr', 50);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HDR10Plus Boost', 'radarr', 1000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HDR10', 'radarr', 500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'HLG', 'radarr', 250);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV Boost', 'radarr', 1500);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV (w/o HDR fallback)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'DV (Disk)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Generated Dynamic HDR', 'radarr', -10000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 01', 'radarr', 2100);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 02', 'radarr', 1900);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Web Tier 03', 'radarr', 1800);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Scene', 'radarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 01', 'radarr', 1700);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 02', 'radarr', 1650);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WEB Tier 03', 'radarr', 1600);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack/Proper', 'radarr', 5);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack2', 'radarr', 6);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Repack3', 'radarr', 7);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Remux Tier 01', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Remux Tier 02', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Remux Tier 03', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'WiTH AD', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German LQ', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German LQ (release title)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'German Microsized', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Line/Mic Dubbed', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'BR-DISK', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'LQ', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'LQ (Release Title)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', '3D', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Upscaled', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Extras', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'AV1', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'No-RlsGroup', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Obfuscated', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Retags', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Bad Dual Groups', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Hardcoded Subs', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'x266 (Codec)', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'VP9', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'MPEG2', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'VC-1', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'MP3', 'radarr', -35000);
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES ('Gantles WEB-2160p Streaming', 'Sing-Along Versions', 'radarr', -35000);

-- --- END
