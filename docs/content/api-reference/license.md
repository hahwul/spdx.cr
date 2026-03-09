+++
title = "License"
description = "License and LicenseList API reference"
weight = 2
+++

## Spdx::License

A struct representing an SPDX license.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | SPDX license identifier (e.g., `"MIT"`) |
| `name` | `String` | Full license name (e.g., `"MIT License"`) |
| `osi_approved?` | `Bool` | Whether OSI-approved |
| `fsf_libre?` | `Bool` | Whether FSF libre |
| `deprecated?` | `Bool` | Whether deprecated in current SPDX list |

### Constructor

```crystal
Spdx::License.new(
  id : String,
  name : String,
  osi_approved : Bool = false,
  fsf_libre : Bool = false,
  deprecated : Bool = false
)
```

### `#to_s : String`

Returns the license ID.

```crystal
lic = Spdx.find_license("MIT")
lic.to_s  # => "MIT"
```

## Spdx::LicenseException

A struct representing an SPDX license exception.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Exception identifier (e.g., `"Classpath-exception-2.0"`) |
| `name` | `String` | Full exception name |
| `deprecated?` | `Bool` | Whether deprecated |

## Spdx::LicenseList

Module for querying the embedded SPDX license database. All lookups are case-insensitive.

### `.licenses : Array(License)`

Returns all 727 SPDX licenses.

### `.exceptions : Array(LicenseException)`

Returns all 84 SPDX license exceptions.

### `.find_license(id : String) : License`

Finds a license by ID (case-insensitive).

```crystal
Spdx::LicenseList.find_license("mit")  # => License(id: "MIT", ...)
```

**Raises:** `Spdx::UnknownLicenseError` if not found.

### `.license?(id : String) : Bool`

Returns `true` if the license ID exists.

### `.find_exception(id : String) : LicenseException`

Finds an exception by ID (case-insensitive).

**Raises:** `Spdx::UnknownExceptionError` if not found.

### `.exception?(id : String) : Bool`

Returns `true` if the exception ID exists.

### `.search(query : String) : Array(License)`

Searches licenses by ID or name substring match.

```crystal
Spdx::LicenseList.search("apache")
# => [License(Apache-1.0), License(Apache-1.1), License(Apache-2.0)]
```

### `.search_exceptions(query : String) : Array(LicenseException)`

Searches exceptions by ID or name substring match.

### `.osi_approved : Array(License)`

Returns only OSI-approved licenses.

### `.fsf_libre : Array(License)`

Returns only FSF libre licenses.
