+++
title = "Errors"
description = "Error handling in spdx.cr"
weight = 5
+++

## Spdx::Error

Base error class for all spdx.cr errors. Extends Crystal's `Exception`.

```crystal
class Spdx::Error < Exception
end
```

## Error Hierarchy

| Error Class | Description |
|-------------|-------------|
| `Spdx::Error` | Base error class |
| `Spdx::ParseError` | Invalid expression syntax |
| `Spdx::UnknownLicenseError` | License ID not found |
| `Spdx::UnknownExceptionError` | Exception ID not found |
| `Spdx::DocumentError` | Document-level errors |
| `Spdx::ValidationError` | Validation failures |
| `Spdx::FormatError` | Format parsing errors |

## Spdx::ParseError

Raised when an SPDX license expression cannot be parsed.

```crystal
begin
  Spdx.parse("")
rescue ex : Spdx::ParseError
  puts ex.message  # => "Empty expression"
end

begin
  Spdx.parse("AND MIT")
rescue ex : Spdx::ParseError
  puts ex.message  # => "Unexpected token 'MIT' at position ..."
end

begin
  Spdx.parse("(MIT AND Apache-2.0")
rescue ex : Spdx::ParseError
  puts ex.message  # => "Expected ')' at position ..."
end
```

## Spdx::UnknownLicenseError

Raised when a license ID is not found in the SPDX list.

```crystal
begin
  Spdx.find_license("FakeLicense-999")
rescue ex : Spdx::UnknownLicenseError
  puts ex.license_id  # => "FakeLicense-999"
  puts ex.message      # => "Unknown SPDX license identifier: FakeLicense-999"
end
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `license_id` | `String` | The license ID that was not found |

## Spdx::UnknownExceptionError

Raised when a license exception ID is not found.

```crystal
begin
  Spdx.find_exception("FakeException")
rescue ex : Spdx::UnknownExceptionError
  puts ex.exception_id  # => "FakeException"
  puts ex.message        # => "Unknown SPDX license exception: FakeException"
end
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `exception_id` | `String` | The exception ID that was not found |

## Spdx::ValidationError

Raised for document validation failures.

```crystal
begin
  raise Spdx::ValidationError.new(["spdxVersion is required", "name is required"])
rescue ex : Spdx::ValidationError
  puts ex.errors  # => ["spdxVersion is required", "name is required"]
end
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `errors` | `Array(String)` | List of validation error messages |

## Spdx::FormatError

Raised when a document format cannot be parsed.

```crystal
begin
  Spdx::Format::Json::Parser.parse("not json")
rescue ex : Spdx::FormatError
  puts ex.message  # => "Invalid SPDX JSON: ..."
end
```

## Error Handling Pattern

```crystal
require "spdx"

def safe_parse(input : String) : Spdx::Expression::Node?
  Spdx.parse(input)
rescue Spdx::ParseError
  nil
end

if ast = safe_parse("MIT AND Apache-2.0")
  puts "Valid: #{ast}"
else
  puts "Invalid expression"
end
```
