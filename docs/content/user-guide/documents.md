+++
title = "Documents"
description = "Working with SPDX 2.3 documents"
weight = 4
+++

## Overview

spdx.cr provides a complete data model for SPDX 2.3 documents, with support for reading and writing both Tag-Value and JSON formats.

## Reading Documents

### From JSON

```crystal
doc = Spdx::Format::Json::Parser.parse_file("example.spdx.json")
puts doc.name             # => "Example"
puts doc.spdx_version     # => "SPDX-2.3"
```

### From Tag-Value

```crystal
doc = Spdx::Format::TagValue::Parser.parse_file("example.spdx")
puts doc.name             # => "Example"
puts doc.spdx_version     # => "SPDX-2.3"
```

## Writing Documents

### To JSON

```crystal
json = Spdx::Format::Json::Generator.generate(doc)
puts json
```

### To Tag-Value

```crystal
tv = Spdx::Format::TagValue::Generator.generate(doc)
puts tv
```

## Format Conversion

Convert between formats by parsing one and generating the other:

```crystal
# Tag-Value to JSON
doc = Spdx::Format::TagValue::Parser.parse_file("input.spdx")
json = Spdx::Format::Json::Generator.generate(doc)
File.write("output.spdx.json", json)

# JSON to Tag-Value
doc = Spdx::Format::Json::Parser.parse_file("input.spdx.json")
tv = Spdx::Format::TagValue::Generator.generate(doc)
File.write("output.spdx", tv)
```

## Creating Documents

Build documents programmatically:

```crystal
doc = Spdx::SpdxDocument.new(
  spdx_version: "SPDX-2.3",
  data_license: "CC0-1.0",
  spdx_id: "SPDXRef-DOCUMENT",
  name: "MyProject",
  document_namespace: "https://example.org/myproject",
  creation_info: Spdx::CreationInfo.new(
    created: "2024-01-01T00:00:00Z",
    creators: ["Tool: my-tool-1.0"]
  )
)

# Add a package
pkg = Spdx::Package.new(
  spdx_id: "SPDXRef-Package",
  name: "my-package",
  download_location: "https://example.org/my-package-1.0.tar.gz",
  license_concluded: "MIT",
  license_declared: "MIT",
  copyright_text: "Copyright 2024 Example"
)
pkg.version_info = "1.0.0"
pkg.primary_package_purpose = Spdx::PrimaryPackagePurpose::LIBRARY
pkg.files_analyzed = false
doc.packages = [pkg]

# Add a DESCRIBES relationship (required)
rel = Spdx::Relationship.new(
  spdx_element_id: "SPDXRef-DOCUMENT",
  relationship_type: Spdx::RelationshipType::DESCRIBES,
  related_spdx_element: "SPDXRef-Package"
)
doc.relationships = [rel]
```

## Validation

Validate a document against SPDX 2.3 requirements:

```crystal
errors = doc.validate

if errors.empty?
  puts "Document is valid"
else
  errors.each { |e| puts "Error: #{e}" }
end

# Or use the convenience method
doc.valid?  # => true/false
```

Validation checks:

**Document level:**
- `spdxVersion` must be `"SPDX-2.3"`
- `dataLicense` must be `"CC0-1.0"`
- `SPDXID` must be `"SPDXRef-DOCUMENT"`
- `name` must not be empty
- `documentNamespace` must be a valid HTTP(S) URI

**Creation info:**
- `created` must be ISO 8601 format (`YYYY-MM-DDThh:mm:ssZ`)
- `creators` must not be empty
- Each creator must start with `Tool:`, `Organization:`, or `Person:`

**Packages:**
- Required fields: `SPDXID`, `name`, `downloadLocation`, `licenseConcluded`, `licenseDeclared`, `copyrightText`
- `SPDXID` must match `SPDXRef-[a-zA-Z0-9.-]+`
- `packageVerificationCode` required when `filesAnalyzed` is `true` (default)

**Files:**
- Required fields: `SPDXID`, `fileName`, `licenseConcluded`, `copyrightText`
- `SPDXID` format validation

**Snippets:**
- Required fields: `SPDXID`, `snippetFromFile`, `ranges`, `licenseConcluded`, `copyrightText`
- `SPDXID` format validation

**Relationships:**
- At least one `DESCRIBES` relationship is required
- `spdxElementId` and `relatedSpdxElement` must not be empty

## Enum Types

The following SPDX 2.3 enum types are available:

### PrimaryPackagePurpose

```crystal
Spdx::PrimaryPackagePurpose::APPLICATION
Spdx::PrimaryPackagePurpose::FRAMEWORK
Spdx::PrimaryPackagePurpose::LIBRARY
Spdx::PrimaryPackagePurpose::CONTAINER
# ... and more
```

### ExternalRefCategory

```crystal
Spdx::ExternalRefCategory::SECURITY
Spdx::ExternalRefCategory::PACKAGE_MANAGER
Spdx::ExternalRefCategory::PERSISTENT_ID
Spdx::ExternalRefCategory::OTHER
```

### FileType

```crystal
Spdx::FileType::SOURCE
Spdx::FileType::BINARY
Spdx::FileType::ARCHIVE
# ... and more
```

## Document Components

An SPDX document can contain:

| Component | Description |
|-----------|-------------|
| `CreationInfo` | Who created the document and when |
| `Package` | Software packages described |
| `FileInfo` | Individual files within packages |
| `Snippet` | Portions of files with different licensing |
| `Relationship` | Connections between elements |
| `Annotation` | Review comments and notes |
| `ExtractedLicensingInfo` | Non-standard license text |
| `ExternalDocumentRef` | References to other SPDX documents |
| `Checksum` | File/package integrity hashes |
| `ExternalRef` | External identifiers (CPE, purl, etc.) |
