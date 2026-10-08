require "json"

module Spdx
  enum AnnotationType
    REVIEW
    OTHER

    def self.from_string(s : String) : self
      parse(s)
    rescue
      raise FormatError.new("Unknown annotation type: #{s}")
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
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

    # Tag-value `SPDXREF` (SPDX 2.3 §12.4). The 2.3 JSON schema has no such
    # property — an annotation is nested in the `annotations` array of the
    # element it annotates — so it is read leniently but never written.
    @[JSON::Field(key: "spdxElementId", ignore_serialize: true)]
    property spdx_element_id : String?

    def initialize(@annotation_date : String, @annotation_type : AnnotationType,
                   @annotator : String, @comment : String, @spdx_element_id : String? = nil)
    end
  end
end
