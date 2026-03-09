module Spdx
  module CLI
    module Commands
      module Validate
        extend self

        def run(file : String)
          unless ::File.exists?(file)
            STDERR.puts "Error: File not found: #{file}"
            exit 1
          end

          doc = parse_document(file)
          errors = doc.validate

          if errors.empty?
            puts "#{file}: Valid SPDX document"
            puts "  Version:   #{doc.spdx_version}"
            puts "  Name:      #{doc.name}"
            puts "  Namespace: #{doc.document_namespace}"
            if pkgs = doc.packages
              puts "  Packages:  #{pkgs.size}"
            end
            if files = doc.files
              puts "  Files:     #{files.size}"
            end
            if rels = doc.relationships
              puts "  Relations: #{rels.size}"
            end
          else
            STDERR.puts "#{file}: Invalid SPDX document"
            STDERR.puts "Errors:"
            errors.each { |e| STDERR.puts "  - #{e}" }
            exit 1
          end
        rescue ex : FormatError | DocumentError
          STDERR.puts "Error: #{ex.message}"
          exit 1
        end

        private def parse_document(file : String) : SpdxDocument
          content = ::File.read(file)
          if file.ends_with?(".json") || content.starts_with?('{')
            Format::Json::Parser.parse(content)
          else
            Format::TagValue::Parser.parse(content)
          end
        end
      end
    end
  end
end
