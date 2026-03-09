require "json"

module Spdx
  module Format
    module Json
      class Parser
        def self.parse(input : String) : SpdxDocument
          SpdxDocument.from_json(input)
        rescue ex : ::JSON::ParseException
          raise FormatError.new("Invalid SPDX JSON: #{ex.message}")
        end

        def self.parse_file(path : String) : SpdxDocument
          parse(::File.read(path))
        end
      end
    end
  end
end
