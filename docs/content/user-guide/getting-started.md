+++
title = "Getting Started"
description = "Installation and first steps with spdx.cr"
weight = 1
+++

## Prerequisites

- [Crystal](https://crystal-lang.org/) >= 1.19.1

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  spdx:
    github: hahwul/spdx.cr
```

Run `shards install` to fetch the library.

## Your First License Expression

```crystal
require "spdx"

# Parse a license expression
ast = Spdx.parse("MIT AND Apache-2.0")
puts ast  # => MIT AND Apache-2.0

# Check validity
puts Spdx.valid_expression?("MIT OR GPL-2.0-only")  # => true
puts Spdx.valid_expression?("AND")                   # => false
```

## Looking Up Licenses

```crystal
require "spdx"

lic = Spdx.find_license("Apache-2.0")
puts lic.name          # => "Apache License 2.0"
puts lic.osi_approved? # => true
puts lic.fsf_libre?    # => true

# Case-insensitive lookup
puts Spdx.license?("mit")  # => true
```

## CLI Tool

spdx.cr also provides a command-line tool. Build it with:

```bash
crystal build src/cli.cr -o bin/spdx
```

Then use it:

```bash
./bin/spdx expression parse "MIT AND Apache-2.0"
./bin/spdx license info MIT
./bin/spdx license list --osi
```

## What is SPDX?

SPDX (Software Package Data Exchange) is an open standard for communicating software bill of materials (SBOM) information, including components, licenses, copyrights, and security references.

An SPDX license expression combines license identifiers with operators:

| Operator | Meaning | Example |
|----------|---------|---------|
| `AND` | Both licenses apply | `MIT AND Apache-2.0` |
| `OR` | Either license applies | `MIT OR GPL-2.0-only` |
| `WITH` | License with exception | `GPL-2.0-only WITH Classpath-exception-2.0` |
| `+` | Or later version | `GPL-2.0+` |

## Next Steps

- **[License Expressions](/user-guide/license-expressions/)** -- Parsing, validating, and formatting expressions
- **[License List](/user-guide/license-list/)** -- Querying the embedded license database
- **[Documents](/user-guide/documents/)** -- Working with SPDX 2.3 documents
