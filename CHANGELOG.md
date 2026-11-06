# Changelog

## Unreleased

### Breaking changes

- `Spdx::Expression::ValidationResult` now splits findings into `errors` and
  `warnings`. `valid?` returns `false` whenever `errors` is non-empty. Unknown
  licenses and unknown exceptions are now `errors`; deprecated identifiers and
  non-canonical casing remain `warnings`. Previously every finding was a
  warning and `valid?` was always `true`.
- The `spdx expression validate` CLI now exits non-zero when the result has
  errors, and prints an `Errors:` section in addition to `Warnings:`.

### Changed

- Embedded SPDX license list refreshed to v3.29.0 (740 licenses, 86
  exceptions): 13 licenses and 2 exceptions added, none removed or newly
  deprecated; `CDDL-1.1`, `CNRI-Python-GPL-Compatible`, `curl` and
  `Python-2.0.1` are now OSI-approved.

### Added

- `scripts/generate_license_data.cr` regenerates `src/spdx/license/data.cr`
  from a tagged spdx/license-list-data release.
- `Spdx::Format::JSON` alias for `Spdx::Format::Json` (matches Crystal stdlib's
  `JSON` module casing). Both names resolve to the same Parser/Generator.

### Fixed

- `Spdx::LicenseList.version` / `Spdx.license_list_version` reported
  `"3.26.0"` although the embedded data was SPDX License List v3.28.0. It now
  reports the generated version (`"3.29.0"`).

## v0.1.0

- First release. Includes the SPDX license expression parser, embedded SPDX
  license list (727 entries), SPDX 2.3 document model, JSON / Tag-Value parse
  and generate, and the `spdx` CLI.
