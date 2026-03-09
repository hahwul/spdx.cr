+++
title = "spdx.cr"
description = "Crystal implementation of the SPDX specification"
+++

A Crystal implementation of the [SPDX (Software Package Data Exchange)](https://spdx.dev/) specification. Parse, validate, and manipulate SPDX license expressions and documents with type-safe Crystal code.

> Implements **SPDX 2.3** with full license expression parsing, document model, Tag-Value and JSON format support.

## Overview

spdx.cr provides a Crystal library and CLI tool for working with SPDX -- the open standard for communicating software bill of materials (SBOM) information. It supports parsing license expressions, querying the official SPDX license list, and reading/writing SPDX documents in both Tag-Value and JSON formats.

## Quick Links

- **[Getting Started](/user-guide/getting-started/)** -- Installation and your first SPDX expression
- **[License Expressions](/user-guide/license-expressions/)** -- Parsing and validating SPDX expressions
- **[API Reference](/api-reference/expression/)** -- Complete API documentation

## Features

- **License Expression Parser** -- Full recursive descent parser with correct operator precedence
- **727 Licenses Embedded** -- Complete SPDX license list available at compile time, no network required
- **SPDX 2.3 Document Model** -- Full data model with JSON serialization
- **Tag-Value & JSON Formats** -- Parse and generate both SPDX formats
- **Expression Validation** -- Validate expressions against the official license list
- **CLI Tool** -- Command-line interface for all operations
- **Zero Dependencies** -- Pure Crystal implementation using only stdlib

## Installation

Add spdx.cr to your `shard.yml`:

```yaml
dependencies:
  spdx:
    github: hahwul/spdx.cr
```

Then run:

```bash
shards install
```

## Quick Example

```crystal
require "spdx"

# Parse a license expression
ast = Spdx.parse("MIT AND Apache-2.0")
puts ast  # => MIT AND Apache-2.0

# Check if an expression is valid
Spdx.valid_expression?("MIT OR GPL-2.0-only")  # => true

# Look up a license
lic = Spdx.find_license("MIT")
puts lic.name          # => "MIT License"
puts lic.osi_approved? # => true
```
