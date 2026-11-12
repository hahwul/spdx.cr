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

- Tag-value `<text>` blocks: a block with nothing after `<text>` on its first
  line kept no leading line break (tools-java keeps it), text after `</text>`
  on the closing line kept the block open, and an unterminated block silently
  swallowed the rest of the document (now a `FormatError`).
- The tag-value generator wraps any value containing `<text>` in a text block,
  so it can no longer open a block when read back.
- Malformed UTF-8 input to the JSON, tag-value and expression parsers raised
  `ArgumentError` from regex matching; it now raises `FormatError` /
  `ParseError`.
- `DocumentRef-a : LicenseRef-b` (white space around `:`) parsed; SPDX 2.3
  Annex D writes `license-ref` as one concatenation, so it is now a
  `ParseError`.
- The expression validator warns on non-canonical exception casing, as it
  already did for licenses.
- `SpdxDocument#validate` reports relationship types that are not in SPDX 2.3
  (they fail the 2.3 JSON schema).
- `spdx expression parse NONE` printed no AST line.
- `Spdx::LicenseList.version` / `Spdx.license_list_version` reported
  `"3.26.0"` although the embedded data was SPDX License List v3.28.0. It now
  reports the generated version (`"3.29.0"`).

## v0.1.0

- First release. Includes the SPDX license expression parser, embedded SPDX
  license list (727 entries), SPDX 2.3 document model, JSON / Tag-Value parse
  and generate, and the `spdx` CLI.
