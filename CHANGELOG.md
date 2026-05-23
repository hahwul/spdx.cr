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

### Added

- `Spdx::Format::JSON` alias for `Spdx::Format::Json` (matches Crystal stdlib's
  `JSON` module casing). Both names resolve to the same Parser/Generator.

## v0.1.0

- First release. Includes the SPDX license expression parser, embedded SPDX
  license list (727 entries), SPDX 2.3 document model, JSON / Tag-Value parse
  and generate, and the `spdx` CLI.
