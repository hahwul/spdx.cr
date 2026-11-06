# Regenerates src/spdx/license/data.cr from spdx/license-list-data.
#
#   crystal run scripts/generate_license_data.cr -- 3.29.0
#
# Fetches json/licenses.json and json/exceptions.json at tag v<version>.
require "http/client"
require "json"
require "uri"

version = (ARGV[0]? || abort "usage: crystal run scripts/generate_license_data.cr -- <version>").lchop('v')
uri = URI.parse("https://raw.githubusercontent.com")

fetch = ->(name : String) do
  path = "/spdx/license-list-data/v#{version}/json/#{name}.json"
  client = HTTP::Client.new(uri)
  client.connect_timeout = 10.seconds
  client.read_timeout = 30.seconds
  res = client.get(path)
  abort "GET #{uri}#{path}: HTTP #{res.status_code}" unless res.success?
  json = JSON.parse(res.body)
  got = json["licenseListVersion"].as_s
  abort "#{name}.json reports licenseListVersion #{got}, expected #{version}" unless got == version
  json
end

licenses = fetch.call("licenses")["licenses"].as_a
exceptions = fetch.call("exceptions")["exceptions"].as_a

[{licenses, "licenseId"}, {exceptions, "licenseExceptionId"}].each do |entries, key|
  abort "empty #{key} list" if entries.empty?
  ids = entries.map(&.[key].as_s.downcase)
  dups = ids.tally.select { |_, n| n > 1 }.keys
  # LicenseList keys its lookup maps on id.downcase.
  abort "#{key} values collide case-insensitively: #{dups.join(", ")}" unless dups.empty?
end

# isFsfLibre is optional upstream; the other flags are required so a renamed
# key fails loudly instead of silently becoming false.
flag = ->(entry : JSON::Any, key : String) { entry[key].as_bool }
fsf = ->(entry : JSON::Any) { entry["isFsfLibre"]?.try(&.as_bool) || false }

source = String.build do |io|
  io << <<-HEADER
    # Auto-generated from SPDX license-list-data by
    # scripts/generate_license_data.cr. Do not edit manually.

    module Spdx
      # Version of the SPDX License List this embedded snapshot was generated from.
      LICENSE_LIST_VERSION = #{version.inspect}

      # :nodoc:
      LICENSE_DATA = [

    HEADER
  licenses.each do |l|
    io << "    {id: " << l["licenseId"].as_s.inspect << ", name: " << l["name"].as_s.inspect
    io << ", osi_approved: " << flag.call(l, "isOsiApproved")
    io << ", fsf_libre: " << fsf.call(l)
    io << ", deprecated: " << flag.call(l, "isDeprecatedLicenseId") << "},\n"
  end
  io << "  ]\n\n  # :nodoc:\n  EXCEPTION_DATA = [\n"
  exceptions.each do |e|
    io << "    {id: " << e["licenseExceptionId"].as_s.inspect << ", name: " << e["name"].as_s.inspect
    io << ", deprecated: " << flag.call(e, "isDeprecatedLicenseId") << "},\n"
  end
  io << "  ]\nend\n"
end

path = File.expand_path("../src/spdx/license/data.cr", __DIR__)
File.write(path, source)
puts "wrote #{path}: #{licenses.size} licenses, #{exceptions.size} exceptions (v#{version})"
