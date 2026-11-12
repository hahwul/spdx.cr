require "json"

module Spdx
  module Format
    module Json
      class Parser
        def self.parse(input : String) : SpdxDocument
          # JSON is UTF-8 (RFC 8259 §8.1); Crystal's JSON parser passes bad
          # bytes through, and `validate`'s regexes then raise ArgumentError.
          raise FormatError.new("Invalid SPDX JSON: input is not valid UTF-8") unless input.valid_encoding?
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
