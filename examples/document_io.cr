require "../src/spdx"

# =============================================================================
# Read an SPDX 2.3 document, inspect it, and convert between formats
# =============================================================================
# spdx.cr supports both the JSON format and the legacy Tag-Value format,
# with a shared SpdxDocument model in the middle. Read with one, write
# with the other — this is the typical "convert" use case.

json_path = File.expand_path("../spec/fixtures/example.spdx.json", __DIR__)
tv_path = File.expand_path("../spec/fixtures/example.spdx", __DIR__)

puts "--- Parse JSON ---"
doc = Spdx::Format::Json::Parser.parse_file(json_path)
puts "  spdxVersion        : #{doc.spdx_version}"
puts "  name               : #{doc.name}"
puts "  documentNamespace  : #{doc.document_namespace}"
puts "  packages           : #{doc.packages.try(&.size) || 0}"
puts "  files              : #{doc.files.try(&.size) || 0}"
puts "  relationships      : #{doc.relationships.try(&.size) || 0}"

puts "\n--- Parse Tag-Value ---"
tv_doc = Spdx::Format::TagValue::Parser.parse_file(tv_path)
puts "  spdxVersion        : #{tv_doc.spdx_version}"
puts "  name               : #{tv_doc.name}"

puts "\n--- Convert JSON -> Tag-Value (head only) ---"
tv_out = Spdx::Format::TagValue::Generator.generate(doc)
puts tv_out.lines.first(8).join("\n")
puts "  ..."

puts "\n--- Convert Tag-Value -> JSON (head only) ---"
json_out = Spdx::Format::Json::Generator.generate(tv_doc, pretty: true)
puts json_out.lines.first(8).join("\n")
puts "  ..."
