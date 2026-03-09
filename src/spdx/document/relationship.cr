require "json"

module Spdx
  enum RelationshipType
    DESCRIBES
    DESCRIBED_BY
    CONTAINS
    CONTAINED_BY
    DEPENDS_ON
    DEPENDENCY_OF
    GENERATES
    GENERATED_FROM
    ANCESTOR_OF
    DESCENDANT_OF
    VARIANT_OF
    DISTRIBUTION_ARTIFACT
    PATCH_FOR
    COPY_OF
    FILE_ADDED
    FILE_DELETED
    FILE_MODIFIED
    EXPANDED_FROM_ARCHIVE
    DYNAMIC_LINK
    STATIC_LINK
    DATA_FILE_OF
    TEST_CASE_OF
    BUILD_TOOL_OF
    DEV_TOOL_OF
    TEST_OF
    TEST_TOOL_OF
    DOCUMENTATION_OF
    OPTIONAL_COMPONENT_OF
    GENERATED_FROM_COPY
    PACKAGE_OF
    HAS_PREREQUISITE
    PREREQUISITE_FOR
    OTHER
    RUNTIME_DEPENDENCY_OF
    DEV_DEPENDENCY_OF
    OPTIONAL_DEPENDENCY_OF
    PROVIDED_DEPENDENCY_OF
    TEST_DEPENDENCY_OF
    BUILD_DEPENDENCY_OF
    EXAMPLE_OF
    GENERATES_COPY
    REQUIREMENT_DESCRIPTION_FOR
    SPECIFICATION_FOR
    VARIANT_DISTRIBUTION_OF
    SECURITY_FIX_FOR
    AFFECTS

    def to_s : String
      super
    end

    def self.from_string(s : String) : self
      parse(s.gsub("-", "_"))
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
    end
  end

  class Relationship
    include JSON::Serializable

    @[JSON::Field(key: "spdxElementId")]
    property spdx_element_id : String

    @[JSON::Field(key: "relationshipType")]
    property relationship_type : RelationshipType

    @[JSON::Field(key: "relatedSpdxElement")]
    property related_spdx_element : String

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    def initialize(@spdx_element_id : String, @relationship_type : RelationshipType,
                   @related_spdx_element : String, @comment : String? = nil)
    end
  end
end
