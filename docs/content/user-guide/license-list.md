+++
title = "License List"
description = "Querying the embedded SPDX license database"
weight = 3
+++

## Overview

spdx.cr embeds the complete SPDX license list (727 licenses and 84 exceptions) as compile-time constants. No network access is needed at runtime.

## Finding Licenses

Look up a license by its SPDX identifier:

```crystal
lic = Spdx.find_license("MIT")
lic.id            # => "MIT"
lic.name          # => "MIT License"
lic.osi_approved? # => true
lic.fsf_libre?    # => true
lic.deprecated?   # => false
```

The lookup is case-insensitive:

```crystal
Spdx.find_license("mit")       # => License(id: "MIT", ...)
Spdx.find_license("apache-2.0") # => License(id: "Apache-2.0", ...)
```

Check existence without raising:

```crystal
Spdx.license?("MIT")           # => true
Spdx.license?("FakeLicense")   # => false
```

## Finding Exceptions

```crystal
exc = Spdx.find_exception("Classpath-exception-2.0")
exc.id          # => "Classpath-exception-2.0"
exc.name        # => "Classpath exception 2.0"
exc.deprecated? # => false

Spdx.exception?("LLVM-exception")  # => true
```

## Searching

Search licenses by ID or name:

```crystal
results = Spdx::LicenseList.search("apache")
results.each do |lic|
  puts "#{lic.id} - #{lic.name}"
end
# Apache-1.0 - Apache License 1.0
# Apache-1.1 - Apache License 1.1
# Apache-2.0 - Apache License 2.0
```

## Filtering

Get only OSI-approved licenses:

```crystal
osi = Spdx::LicenseList.osi_approved
puts osi.size  # => number of OSI-approved licenses
osi.all?(&.osi_approved?)  # => true
```

Get only FSF libre licenses:

```crystal
fsf = Spdx::LicenseList.fsf_libre
puts fsf.size  # => number of FSF libre licenses
```

## Full License List

Access the complete list:

```crystal
all = Spdx::LicenseList.licenses
puts all.size  # => 727

all_exceptions = Spdx::LicenseList.exceptions
puts all_exceptions.size  # => 84
```
