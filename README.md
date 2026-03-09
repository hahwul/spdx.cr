# spdx.cr

SPDX license expression parser and SPDX 2.3 document toolkit for Crystal. Includes 727 embedded SPDX licenses with zero external dependencies.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  spdx:
    github: hahwul/spdx.cr
```

Then run `shards install`.

## Usage

### Library

```crystal
require "spdx"

# Parse license expression
ast = Spdx.parse("MIT AND Apache-2.0")

# Validate expression
Spdx.valid_expression?("MIT OR GPL-2.0-only")  # => true

# Lookup license
license = Spdx.find_license("MIT")
license.name          # => "MIT License"
license.osi_approved? # => true

# Check license existence
Spdx.license?("MIT") # => true
```

### CLI

```bash
# License expression
spdx expression parse "MIT AND Apache-2.0"
spdx expression validate "GPL-2.0-only WITH Classpath-exception-2.0"

# License lookup
spdx license list --osi
spdx license info MIT
spdx license search apache

# SPDX document
spdx validate document.spdx.json
spdx convert document.spdx --format json
```

## Features

- License expression parser with full operator precedence (AND, OR, WITH, +)
- 727 SPDX licenses embedded at compile time
- SPDX 2.3 document model with validation
- JSON and Tag-Value format support (parse / generate / convert)
- CLI tool

## Contributing

1. Fork it (<https://github.com/hahwul/spdx.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
