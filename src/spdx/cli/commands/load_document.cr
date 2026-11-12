module Spdx
  module CLI
    module Commands
      # Reads an SPDX document file, JSON or tag-value. An unreadable path
      # (a directory, no permission) raises `DocumentError` instead of an
      # unhandled `IO::Error`.
      def self.load_document(file : String) : SpdxDocument
        content = ::File.read(file)
        # JSON may begin with white space (RFC 8259 §2); a tag-value line
        # never starts with '{'.
        if file.ends_with?(".json") || content.lstrip.starts_with?('{')
          Format::Json::Parser.parse(content)
        else
          Format::TagValue::Parser.parse(content)
        end
      rescue ex : IO::Error
        raise DocumentError.new("Cannot read #{file}: #{ex.message}")
      end
    end
  end
end
