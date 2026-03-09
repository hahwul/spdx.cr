require "json"

module Spdx
  class Snippet
    include JSON::Serializable

    @[JSON::Field(key: "SPDXID")]
    property spdx_id : String

    @[JSON::Field(key: "snippetFromFile")]
    property snippet_from_file : String

    @[JSON::Field(key: "ranges")]
    property ranges : Array(SnippetRange)

    @[JSON::Field(key: "licenseConcluded")]
    property license_concluded : String

    @[JSON::Field(key: "copyrightText")]
    property copyright_text : String

    @[JSON::Field(key: "licenseInfoInSnippets", emit_null: false)]
    property license_info_in_snippets : Array(String)?

    @[JSON::Field(key: "name", emit_null: false)]
    property name : String?

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    @[JSON::Field(key: "licenseComments", emit_null: false)]
    property license_comments : String?

    @[JSON::Field(key: "attributionTexts", emit_null: false)]
    property attribution_texts : Array(String)?

    def initialize(@spdx_id : String, @snippet_from_file : String,
                   @ranges : Array(SnippetRange), @license_concluded : String,
                   @copyright_text : String)
    end
  end

  class SnippetRange
    include JSON::Serializable

    @[JSON::Field(key: "startPointer")]
    property start_pointer : RangePointer

    @[JSON::Field(key: "endPointer")]
    property end_pointer : RangePointer

    def initialize(@start_pointer : RangePointer, @end_pointer : RangePointer)
    end
  end

  class RangePointer
    include JSON::Serializable

    @[JSON::Field(key: "reference", emit_null: false)]
    property reference : String?

    @[JSON::Field(key: "offset", emit_null: false)]
    property offset : Int32?

    @[JSON::Field(key: "lineNumber", emit_null: false)]
    property line_number : Int32?

    def initialize(@reference : String? = nil, @offset : Int32? = nil,
                   @line_number : Int32? = nil)
    end
  end
end
