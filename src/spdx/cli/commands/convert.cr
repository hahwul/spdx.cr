module Spdx
  module CLI
    module Commands
      module Convert
        extend self

        def run(file : String, format : String)
          unless ::File.exists?(file)
            STDERR.puts "Error: File not found: #{file}"
            exit 1
          end

          doc = parse_document(file)

          case format.downcase
          when "json"
            puts Format::Json::Generator.generate(doc)
          when "tv", "tag-value", "tagvalue"
            puts Format::TagValue::Generator.generate(doc)
          else
            STDERR.puts "Error: Unknown format '#{format}'. Use 'json' or 'tv'"
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
