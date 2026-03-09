require "json"

module Spdx
  enum AnnotationType
    REVIEW
    OTHER

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      parse(pull.read_string)
    end
  end

  class Annotation
    include JSON::Serializable

    @[JSON::Field(key: "annotationDate")]
    property annotation_date : String

    @[JSON::Field(key: "annotationType")]
    property annotation_type : AnnotationType

    @[JSON::Field(key: "annotator")]
    property annotator : String

    @[JSON::Field(key: "comment")]
    property comment : String

    @[JSON::Field(key: "spdxElementId", emit_null: false)]
    property spdx_element_id : String?

    def initialize(@annotation_date : String, @annotation_type : AnnotationType,
                   @annotator : String, @comment : String, @spdx_element_id : String? = nil)
    end
  end
end
