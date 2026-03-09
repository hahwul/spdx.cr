require "json"

module Spdx
  class CreationInfo
    include JSON::Serializable

    @[JSON::Field(key: "created")]
    property created : String

    @[JSON::Field(key: "creators")]
    property creators : Array(String)

    @[JSON::Field(key: "licenseListVersion", emit_null: false)]
    property license_list_version : String?

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    def initialize(@created : String, @creators : Array(String),
                   @license_list_version : String? = nil, @comment : String? = nil)
    end
  end
end
