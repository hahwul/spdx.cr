+++
title = "Expression"
description = "Expression parser API reference"
weight = 1
+++

## Spdx (top-level)

Convenience methods on the `Spdx` module for working with expressions.

### `.parse(expression : String) : Expression::Node`

Parses an SPDX license expression string and returns an AST node.

```crystal
ast = Spdx.parse("MIT AND Apache-2.0")
```

**Raises:** `Spdx::ParseError` if the expression is invalid.

### `.valid_expression?(expression : String) : Bool`

Returns `true` if the expression is syntactically valid.

```crystal
Spdx.valid_expression?("MIT AND Apache-2.0")  # => true
Spdx.valid_expression?("AND")                  # => false
```

### `.validate_expression(expression : String) : Expression::ValidationResult`

Parses and validates the expression against the SPDX license list.

```crystal
result = Spdx.validate_expression("MIT AND FakeLicense-1.0")
result.valid?    # => true
result.warnings  # => ["Unknown license: FakeLicense-1.0"]
```

**Raises:** `Spdx::ParseError` if the expression is syntactically invalid.

## Expression::Parser

### `.parse(input : String) : Node`

Parses an SPDX license expression using a recursive descent parser.

Operator precedence (highest to lowest): `+` > `WITH` > `AND` > `OR`

```crystal
node = Spdx::Expression::Parser.parse("MIT OR Apache-2.0 AND GPL-2.0-only")
# Parsed as: MIT OR (Apache-2.0 AND GPL-2.0-only)
```

## Expression::Validator

### `.validate(node : Node) : ValidationResult`

Validates an AST against the SPDX license list. Returns a `ValidationResult` with warnings.

```crystal
ast = Spdx::Expression::Parser.parse("GPL-2.0")
result = Spdx::Expression::Validator.validate(ast)
result.warnings  # => ["Deprecated license: GPL-2.0"]
```

## Expression::ValidationResult

| Property | Type | Description |
|----------|------|-------------|
| `valid?` | `Bool` | Always `true` (syntactic validity checked during parsing) |
| `warnings` | `Array(String)` | Warnings about unknown/deprecated licenses or exceptions |

## Expression::Formatter

### `.format(node : Node) : String`

Converts an AST node back to a string.

```crystal
ast = Spdx::Expression::Parser.parse("MIT AND Apache-2.0")
Spdx::Expression::Formatter.format(ast)  # => "MIT AND Apache-2.0"
```

### `.normalize(expression : String) : String`

Parses and re-formats an expression, normalizing whitespace.

```crystal
Spdx::Expression::Formatter.normalize("MIT   AND   Apache-2.0")
# => "MIT AND Apache-2.0"
```

## AST Node Types

### Expression::LicenseNode

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | License identifier (e.g., `"MIT"`) |
| `or_later?` | `Bool` | Whether `+` was specified |

### Expression::LicenseRefNode

| Property | Type | Description |
|----------|------|-------------|
| `license_ref` | `String` | License reference (e.g., `"LicenseRef-custom-1"`) |
| `document_ref` | `String?` | Document reference if present |

### Expression::WithExceptionNode

| Property | Type | Description |
|----------|------|-------------|
| `license` | `Node` | The license node |
| `exception` | `String` | Exception identifier |

### Expression::CompoundNode

| Property | Type | Description |
|----------|------|-------------|
| `operator` | `Operator` | `AND` or `OR` |
| `left` | `Node` | Left operand |
| `right` | `Node` | Right operand |

All node types implement `#to_s` for string output.
