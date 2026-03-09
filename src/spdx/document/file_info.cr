require "json"

module Spdx
  enum FileType
    SOURCE
    BINARY
    ARCHIVE
    APPLICATION
    AUDIO
    IMAGE
    TEXT
    VIDEO
    DOCUMENTATION
    SPDX
    OTHER

    def to_s : String
      super
    end

    def self.from_string(s : String) : self
      parse(s)
    rescue
      raise FormatError.new("Unknown file type: #{s}")
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
    end
  end

  class FileInfo
    include JSON::Serializable

    @[JSON::Field(key: "SPDXID")]
    property spdx_id : String

    @[JSON::Field(key: "fileName")]
    property file_name : String

    @[JSON::Field(key: "fileTypes", emit_null: false)]
    property file_types : Array(FileType)?

    @[JSON::Field(key: "checksums", emit_null: false)]
    property checksums : Array(Checksum)?

    @[JSON::Field(key: "licenseConcluded")]
    property license_concluded : String

    @[JSON::Field(key: "licenseInfoInFiles", emit_null: false)]
    property license_info_in_files : Array(String)?

    @[JSON::Field(key: "copyrightText")]
    property copyright_text : String

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    @[JSON::Field(key: "noticeText", emit_null: false)]
    property notice_text : String?

    @[JSON::Field(key: "fileContributors", emit_null: false)]
    property file_contributors : Array(String)?

    @[JSON::Field(key: "attributionTexts", emit_null: false)]
    property attribution_texts : Array(String)?

    def initialize(@spdx_id : String, @file_name : String,
                   @license_concluded : String, @copyright_text : String)
    end
  end
end
