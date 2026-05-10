# Changelog for plsql-uuid-v7

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.1.0] - 2026-05-07
### Added
- Test suite `test_uuidv7.sql`: validates format, version nibble, RFC 9562 variant, lowercase output, hyphen positions, and uniqueness of consecutive UUIDs.
- Test suite `test_uuidv7_monotonic.sql`: bulk generation of 10,000 UUIDs validated for no duplicates, correct format, version 7, and RFC 9562 variant across all entries.
- `install/uninstall.sql` script for clean package removal.

### Changed
- Migrated source layout to Maven-style structure: `src/main/oracle/packages/` and `src/test/oracle/pkg_uuids/`.
- `install/install.sql` updated to reference new source paths.
- All source files standardised to 2-space indentation.
- Removed hardcoded schema from package definition; installation targets the connected schema.
- Monotonicity state comment translated to English.

## [1.0.0] - 2026-05-01
### Added
- Initial release of the UUID v7 implementation compliant with RFC 9562.
- Package specification (`pl_uuidv7.pks`) and body (`pl_uuidv7.pkb`).
- Unix epoch millisecond timestamp (48 bits), version 7 nibble, and RFC 9562 variant bits.
- Session-scoped monotonicity counter using package-level state variables.
- `install/install.sql` for schema-agnostic deployment.
- Documentation: getting started guide, API reference, and RFC 9562 compliance notes.