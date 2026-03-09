require "json"

module Spdx
  class ExternalDocumentRef
    include JSON::Serializable

    @[JSON::Field(key: "externalDocumentId")]
    property external_document_id : String

    @[JSON::Field(key: "spdxDocument")]
    property spdx_document : String

    @[JSON::Field(key: "checksum")]
    property checksum : Checksum

    def initialize(@external_document_id : String, @spdx_document : String, @checksum : Checksum)
    end
  end
end
