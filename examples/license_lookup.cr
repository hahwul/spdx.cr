require "../src/spdx"

# =============================================================================
# License lookup against the embedded SPDX license list (727 licenses)
# =============================================================================
# `Spdx.license?` checks existence; `Spdx.find_license` returns a License
# struct with metadata (OSI / FSF / deprecated flags). Use these to surface
# upstream license info inside SBOM or audit tooling.

puts "--- existence checks ---"
%w[MIT GPL-2.0-only Apache-2.0 NotALicense GPL-2.0].each do |id|
  puts "  Spdx.license?(#{id.inspect}) => #{Spdx.license?(id)}"
end

puts "\n--- find_license metadata ---"
%w[MIT Apache-2.0 GPL-2.0-only CC0-1.0].each do |id|
  lic = Spdx.find_license(id)
  flags = [] of String
  flags << "osi" if lic.osi_approved?
  flags << "fsf" if lic.fsf_libre?
  flags << "deprecated" if lic.deprecated?
  puts "  #{lic.id.ljust(20)} #{lic.name.ljust(40)} [#{flags.join(",")}]"
end

puts "\n--- exception lookup ---"
%w[Classpath-exception-2.0 LLVM-exception unknown-exception].each do |id|
  if Spdx.exception?(id)
    exc = Spdx.find_exception(id)
    puts "  #{id.ljust(30)} => #{exc.name}"
  else
    puts "  #{id.ljust(30)} => (not found)"
  end
end
