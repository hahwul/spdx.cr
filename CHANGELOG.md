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
- The expression parser raises `ParseError` ("Malformed LicenseRef: …" /
  "Malformed DocumentRef: …") when the idstring after `LicenseRef-` or
  `DocumentRef-` is empty or has characters other than letters, digits, `-`
  and `.` (SPDX 2.3 Annex D). `valid_expression?("LicenseRef-")` is now
  `false`, and `validate_expression` raises instead of returning a
  "Malformed LicenseRef" error; before, only the validator flagged it.
- Tag-value `<text>` blocks keep CRLF line breaks (`"a\r\nb"`) instead of
  turning them into `"\n"`. tools-java normalises them; outside text blocks
  nothing changes, and first/last-line trimming is unchanged.

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

- `SpdxDocument#validate` accepted `created` timestamps with an out-of-range
  month, day, hour, minute or second (`2024-13-01T25:00:00Z`); it now uses
  the SPDX 2.3 JSON schema's ranges (fractional seconds are still accepted).
- `SpdxDocument#validate` did not check what the SPDX 2.3 JSON schema and
  spec enforce on fields other than `created`: package `releaseDate`,
  `builtDate` and `validUntilDate`; each annotation's `annotationDate`,
  `annotator` and `comment` (clause 12); checksum values (hexadecimal,
  §8.4); and `externalDocumentRefs` (§6.6: `DocumentRef-` id, unique, a URI
  without `#`). A license expression's `DocumentRef-x:` must now also be
  declared in `externalDocumentRefs`, as element references already had to be.
- `spdx validate` / `spdx convert` crashed with an unhandled `IO::Error` on a
  directory or unreadable file, and read a JSON file starting with white
  space as tag-value.
- `spdx license list --osi --fsf` ignored `--fsf`; the filters now combine.
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
- `SpdxDocument#validate` and `Expression::Validator.validate` raised
  `ArgumentError` on invalid UTF-8 in a document built in code or loaded with
  `SpdxDocument.from_json`. They now report it as an error.
- SPDXID, `LicenseRef-`, `DocumentRef-`, creator and `created` checks used
  `^…$`, so a value with a trailing newline (`"SPDXRef-a\n"`) passed. They now
  anchor with `\A…\z`.
- Expression parsing was quadratic on non-ASCII input (`String#[]` by char
  index), and a long flat AND/OR chain built an AST deep enough to overflow
  the stack in `to_s`/the validator. The tokenizer now indexes a char array,
  and more than `Parser::MAX_OPERATORS` (10 000) operators is a `ParseError`.
- `Spdx::LicenseList.version` / `Spdx.license_list_version` reported
  `"3.26.0"` although the embedded data was SPDX License List v3.28.0. It now
  reports the generated version (`"3.29.0"`).

## v0.1.0

- First release. Includes the SPDX license expression parser, embedded SPDX
  license list (727 entries), SPDX 2.3 document model, JSON / Tag-Value parse
  and generate, and the `spdx` CLI.
