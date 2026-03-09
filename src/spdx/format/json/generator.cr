require "json"

module Spdx
  module Format
    module Json
      class Generator
        def self.generate(doc : SpdxDocument, pretty : Bool = true) : String
          if pretty
            doc.to_pretty_json
          else
            doc.to_json
          end
        end
      end
    end
  end
end
