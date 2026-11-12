+++
title = "CLI"
description = "Command-line interface reference"
weight = 5
+++

## Building

Build the CLI binary from source:

```bash
crystal build src/cli.cr -o bin/spdx
```

Or use the shard target:

```bash
shards build
```

## Commands

### spdx expression parse

Parse a license expression and display the AST:

```bash
$ spdx expression parse "MIT AND Apache-2.0"
Expression: MIT AND Apache-2.0
Parsed:     MIT AND Apache-2.0
AND:
  License: MIT
  License: Apache-2.0
```

```bash
$ spdx expression parse "GPL-2.0-only WITH Classpath-exception-2.0 OR MIT"
Expression: GPL-2.0-only WITH Classpath-exception-2.0 OR MIT
Parsed:     GPL-2.0-only WITH Classpath-exception-2.0 OR MIT
OR:
  WITH:
    License: GPL-2.0-only
    Exception: Classpath-exception-2.0
  License: MIT
```

### spdx expression validate

Validate an expression against the SPDX license list:

```bash
$ spdx expression validate "MIT AND Apache-2.0"
Expression: MIT AND Apache-2.0
Valid:      yes
```

```bash
$ spdx expression validate "MIT AND FakeLicense"
Expression: MIT AND FakeLicense
Valid:      no
Errors:
  - Unknown license: FakeLicense
```

Unknown licenses and exceptions are errors and make the command exit with
status 1; deprecated identifiers and non-canonical casing are printed under
`Warnings:` and still exit 0.

### spdx license list

List SPDX licenses with optional filters:

```bash
$ spdx license list
$ spdx license list --osi    # OSI-approved only
$ spdx license list --fsf    # FSF libre only
$ spdx license list --osi --fsf    # both OSI-approved and FSF libre
```

Deprecated identifiers are not listed.

### spdx license info

Show details for a specific license:

```bash
$ spdx license info MIT
ID:           MIT
Name:         MIT License
OSI Approved: yes
FSF Libre:    yes
Deprecated:   no
```

### spdx license search

Search licenses by ID or name:

```bash
$ spdx license search apache
ID                             Name
--------------------------------------------------------------------------------
Apache-1.0                     Apache License 1.0 [FSF]
Apache-1.1                     Apache License 1.1 [OSI] [FSF]
Apache-2.0                     Apache License 2.0 [OSI] [FSF]

Found: 3 licenses
```

### spdx validate

Validate an SPDX document (JSON or Tag-Value):

```bash
$ spdx validate document.spdx.json
document.spdx.json: Valid SPDX document
  Version:   SPDX-2.3
  Name:      Example
  Namespace: https://example.org/example
  Packages:  1
  Files:     1
  Relations: 2
```

### spdx convert

Convert between SPDX formats:

```bash
# Tag-Value to JSON
$ spdx convert document.spdx --format json

# JSON to Tag-Value
$ spdx convert document.spdx.json --format tv
```

### spdx version

```bash
$ spdx version
spdx 0.1.0
```
