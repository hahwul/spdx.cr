+++
title = "License Expressions"
description = "Parsing, validating, and formatting SPDX license expressions"
weight = 2
+++

## Parsing Expressions

Use `Spdx.parse` to parse an SPDX license expression into an AST:

```crystal
ast = Spdx.parse("MIT AND Apache-2.0")
puts ast  # => MIT AND Apache-2.0
```

The parser implements a recursive descent algorithm with correct operator precedence:

1. `+` (or-later) -- highest precedence
2. `WITH` (exception)
3. `AND` (conjunction)
4. `OR` (disjunction) -- lowest precedence

## Operator Precedence

AND binds tighter than OR, so:

```crystal
ast = Spdx.parse("MIT OR Apache-2.0 AND GPL-2.0-only")
puts ast  # => MIT OR Apache-2.0 AND GPL-2.0-only
# Equivalent to: MIT OR (Apache-2.0 AND GPL-2.0-only)
```

Use parentheses to override:

```crystal
ast = Spdx.parse("(MIT OR Apache-2.0) AND GPL-2.0-only")
puts ast  # => (MIT OR Apache-2.0) AND GPL-2.0-only
```

## License Identifiers

Standard SPDX license identifiers:

```crystal
ast = Spdx.parse("MIT")
# => LicenseNode(id: "MIT")
```

Or-later modifier with `+`:

```crystal
ast = Spdx.parse("GPL-2.0+")
# => LicenseNode(id: "GPL-2.0", or_later: true)
```

## WITH Exceptions

Attach a license exception using `WITH`:

```crystal
ast = Spdx.parse("GPL-2.0-only WITH Classpath-exception-2.0")
# => WithExceptionNode(license: GPL-2.0-only, exception: Classpath-exception-2.0)
```

## LicenseRef and DocumentRef

User-defined license references:

```crystal
ast = Spdx.parse("LicenseRef-custom-1")
# => LicenseRefNode(license_ref: "LicenseRef-custom-1")

ast = Spdx.parse("DocumentRef-ext1:LicenseRef-custom-1")
# => LicenseRefNode(document_ref: "DocumentRef-ext1", license_ref: "LicenseRef-custom-1")
```

## Validation

Check if an expression string is valid:

```crystal
Spdx.valid_expression?("MIT AND Apache-2.0")  # => true
Spdx.valid_expression?("AND MIT")              # => false
```

Validate against the official license list to get warnings:

```crystal
result = Spdx.validate_expression("MIT AND FakeLicense-1.0")
result.valid?     # => true (syntactically valid)
result.warnings   # => ["Unknown license: FakeLicense-1.0"]
```

The validator also warns about deprecated licenses:

```crystal
result = Spdx.validate_expression("GPL-2.0")
result.warnings  # => ["Deprecated license: GPL-2.0"]
# Use GPL-2.0-only or GPL-2.0-or-later instead
```

## Formatting

Normalize whitespace and formatting in expressions:

```crystal
normalized = Spdx::Expression::Formatter.normalize("MIT   AND   Apache-2.0")
puts normalized  # => "MIT AND Apache-2.0"
```

## Error Handling

The parser raises `Spdx::ParseError` for invalid expressions:

```crystal
begin
  Spdx.parse("")
rescue ex : Spdx::ParseError
  puts ex.message  # => "Empty expression"
end

begin
  Spdx.parse("(MIT AND Apache-2.0")
rescue ex : Spdx::ParseError
  puts ex.message  # => "Expected ')' at position ..."
end
```
