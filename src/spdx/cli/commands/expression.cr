module Spdx
  module CLI
    module Commands
      module Expression
        extend self

        def parse_expression(expr : String)
          ast = Spdx.parse(expr)
          puts "Expression: #{expr}"
          puts "Parsed:     #{ast}"
          print_ast(ast, 0)
        rescue ex : ParseError
          STDERR.puts "Error: #{ex.message}"
          exit 1
        end

        def validate_expression(expr : String)
          result = Spdx.validate_expression(expr)
          puts "Expression: #{expr}"
          puts "Valid:      yes"
          if result.warnings.any?
            puts "Warnings:"
            result.warnings.each { |w| puts "  - #{w}" }
          end
        rescue ex : ParseError
          STDERR.puts "Expression: #{expr}"
          STDERR.puts "Valid:      no"
          STDERR.puts "Error:      #{ex.message}"
          exit 1
        end

        private def print_ast(node : Spdx::Expression::Node, depth : Int32)
          indent = "  " * depth
          case node
          when Spdx::Expression::LicenseNode
            suffix = node.or_later? ? " (or-later)" : ""
            puts "#{indent}License: #{node.id}#{suffix}"
          when Spdx::Expression::LicenseRefNode
            if doc = node.document_ref
              puts "#{indent}DocumentRef: #{doc}:#{node.license_ref}"
            else
              puts "#{indent}LicenseRef: #{node.license_ref}"
            end
          when Spdx::Expression::WithExceptionNode
            puts "#{indent}WITH:"
            print_ast(node.license, depth + 1)
            puts "#{indent}  Exception: #{node.exception}"
          when Spdx::Expression::CompoundNode
            puts "#{indent}#{node.operator}:"
            print_ast(node.left, depth + 1)
            print_ast(node.right, depth + 1)
          end
        end
      end
    end
  end
end
