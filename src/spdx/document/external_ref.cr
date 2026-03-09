require "json"

module Spdx
  enum ExternalRefCategory
    SECURITY
    PACKAGE_MANAGER
    PERSISTENT_ID
    OTHER

    def to_s : String
      case self
      when SECURITY        then "SECURITY"
      when PACKAGE_MANAGER then "PACKAGE-MANAGER"
      when PERSISTENT_ID   then "PERSISTENT-ID"
      when OTHER           then "OTHER"
      else                      super
      end
    end

    def self.from_string(s : String) : self
      case s.upcase
      when "SECURITY"        then SECURITY
      when "PACKAGE-MANAGER" then PACKAGE_MANAGER
      when "PERSISTENT-ID"   then PERSISTENT_ID
      when "OTHER"           then OTHER
      else
        raise FormatError.new("Unknown external reference category: #{s}")
      end
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
    end
  end

  class ExternalRef
    include JSON::Serializable

    @[JSON::Field(key: "referenceCategory")]
    property reference_category : ExternalRefCategory

    @[JSON::Field(key: "referenceType")]
    property reference_type : String

    @[JSON::Field(key: "referenceLocator")]
    property reference_locator : String

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    def initialize(@reference_category : ExternalRefCategory, @reference_type : String,
                   @reference_locator : String, @comment : String? = nil)
    end
  end
end
