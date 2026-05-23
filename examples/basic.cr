require "../src/spdx"

# =============================================================================
# Basic usage: parse and validate SPDX license expressions
# =============================================================================
# `Spdx.parse` returns an AST (Expression::Node tree).
# `Spdx.valid_expression?` is a non-raising boolean check.
# `Spdx.validate_expression` returns a structured ValidationResult that knows
# about deprecated identifiers and unknown licenses/exceptions.

puts "--- Parse ---"
ast = Spdx.parse("MIT AND Apache-2.0")
puts "ast.class: #{ast.class}"
puts "ast.to_s : #{ast}"

puts "\n--- valid_expression? ---"
%w[
  MIT
  GPL-2.0-only
  Apache-2.0+
  MIT\ OR\ GPL-2.0-only
  (MIT\ OR\ Apache-2.0)\ AND\ BSD-3-Clause
  GPL-2.0-only\ WITH\ Classpath-exception-2.0
  NotARealLicense-9.9
].each do |expr|
  puts "  #{expr.ljust(60)} => #{Spdx.valid_expression?(expr)}"
end

puts "\n--- validate_expression (errors vs warnings) ---"
# `validate_expression` walks the AST and splits findings into:
#   - errors   : hard failures (unknown license / exception). valid? is false.
#   - warnings : soft issues (deprecated identifier, non-canonical casing).
#                valid? stays true.
[
  "GPL-2.0 OR NotARealLicense", # GPL-2.0 deprecated (warn), NotARealLicense unknown (error)
  "GPL-2.0 OR MIT",             # only deprecated -> still valid
  "MIT AND Apache-2.0",         # canonical and current -> clean
].each do |expr|
  result = Spdx.validate_expression(expr)
  puts "  expression: #{expr}"
  puts "    valid?   : #{result.valid?}"
  puts "    errors   : #{result.errors}"
  puts "    warnings : #{result.warnings}"
end
