+++
title = "Formats"
description = "Tag-Value and JSON format API reference"
weight = 4
+++

## Tag-Value Format

### Format::TagValue::Parser

Parses SPDX Tag-Value format into a document model.

#### `.parse(input : String) : SpdxDocument`

```crystal
doc = Spdx::Format::TagValue::Parser.parse(tag_value_string)
```

#### `.parse_file(path : String) : SpdxDocument`

```crystal
doc = Spdx::Format::TagValue::Parser.parse_file("example.spdx")
```

Supports:
- Standard `Tag: Value` pairs
- Multiline values with `<text>...</text>`
- Section detection (Document, Package, File, Snippet, License, Annotation)
- Relationship parsing with comments
- External document references
- Checksum parsing (all 17 algorithms)
- Repeatable tags: `PackageChecksum`, `FileChecksum`, `FileType`, `FileContributor`, `ExternalRef`, `PackageLicenseInfoFromFiles`, `LicenseInfoInFile`, `LicenseInfoInSnippet`, `LicenseCrossReference`, `PackageAttributionText`, `FileAttributionText`, `SnippetAttributionText`

### Format::TagValue::Generator

Generates SPDX Tag-Value format from a document model.

#### `.generate(doc : SpdxDocument) : String`

```crystal
output = Spdx::Format::TagValue::Generator.generate(doc)
```

Output order follows the SPDX specification:
1. Document header (SPDXVersion, DataLicense, SPDXID, DocumentName, DocumentNamespace)
2. Creation info (Creator, Created, LicenseListVersion)
3. External document references
4. Packages (including checksums, external refs, attribution texts, primary purpose, dates)
5. Files (including checksums, contributors, attribution texts)
6. Snippets (including license comments, attribution texts)
7. Extracted licensing info
8. Relationships
9. Annotations

## JSON Format

### Format::Json::Parser

Parses SPDX JSON format using `JSON::Serializable`.

#### `.parse(input : String) : SpdxDocument`

```crystal
doc = Spdx::Format::Json::Parser.parse(json_string)
```

**Raises:** `Spdx::FormatError` if the JSON is invalid.

#### `.parse_file(path : String) : SpdxDocument`

```crystal
doc = Spdx::Format::Json::Parser.parse_file("example.spdx.json")
```

### Format::Json::Generator

Generates SPDX JSON format.

#### `.generate(doc : SpdxDocument, pretty : Bool = true) : String`

```crystal
# Pretty-printed JSON (default)
json = Spdx::Format::Json::Generator.generate(doc)

# Compact JSON
json = Spdx::Format::Json::Generator.generate(doc, pretty: false)
```

## Round-Trip Example

```crystal
# Read Tag-Value, write JSON
doc = Spdx::Format::TagValue::Parser.parse_file("input.spdx")
json = Spdx::Format::Json::Generator.generate(doc)
File.write("output.spdx.json", json)

# Read JSON, write Tag-Value
doc = Spdx::Format::Json::Parser.parse_file("input.spdx.json")
tv = Spdx::Format::TagValue::Generator.generate(doc)
File.write("output.spdx", tv)
```
