require "json"

module Spdx
  class ExtractedLicensingInfo
    include JSON::Serializable

    @[JSON::Field(key: "licenseId")]
    property license_id : String

    @[JSON::Field(key: "extractedText")]
    property extracted_text : String

    @[JSON::Field(key: "name", emit_null: false)]
    property name : String?

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    @[JSON::Field(key: "seeAlsos", emit_null: false)]
    property see_alsos : Array(String)?

    def initialize(@license_id : String, @extracted_text : String,
                   @name : String? = nil, @comment : String? = nil,
                   @see_alsos : Array(String)? = nil)
    end
  end
end
