require "json"

module Spdx
  enum PrimaryPackagePurpose
    APPLICATION
    FRAMEWORK
    LIBRARY
    CONTAINER
    OPERATING_SYSTEM
    DEVICE
    FIRMWARE
    SOURCE
    ARCHIVE
    FILE
    INSTALL
    OTHER

    def to_s : String
      case self
      when OPERATING_SYSTEM then "OPERATING-SYSTEM"
      else                       super
      end
    end

    def self.from_string(s : String) : self
      case s.upcase.gsub("-", "_")
      when "APPLICATION"      then APPLICATION
      when "FRAMEWORK"        then FRAMEWORK
      when "LIBRARY"          then LIBRARY
      when "CONTAINER"        then CONTAINER
      when "OPERATING_SYSTEM" then OPERATING_SYSTEM
      when "DEVICE"           then DEVICE
      when "FIRMWARE"         then FIRMWARE
      when "SOURCE"           then SOURCE
      when "ARCHIVE"          then ARCHIVE
      when "FILE"             then FILE
      when "INSTALL"          then INSTALL
      when "OTHER"            then OTHER
      else
        raise FormatError.new("Unknown primary package purpose: #{s}")
      end
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
    end
  end

  class Package
    include JSON::Serializable

    @[JSON::Field(key: "SPDXID")]
    property spdx_id : String

    @[JSON::Field(key: "name")]
    property name : String

    @[JSON::Field(key: "versionInfo", emit_null: false)]
    property version_info : String?

    @[JSON::Field(key: "packageFileName", emit_null: false)]
    property package_file_name : String?

    @[JSON::Field(key: "supplier", emit_null: false)]
    property supplier : String?

    @[JSON::Field(key: "originator", emit_null: false)]
    property originator : String?

    @[JSON::Field(key: "downloadLocation")]
    property download_location : String

    @[JSON::Field(key: "filesAnalyzed", emit_null: false)]
    property files_analyzed : Bool?

    @[JSON::Field(key: "packageVerificationCode", emit_null: false)]
    property package_verification_code : PackageVerificationCode?

    @[JSON::Field(key: "checksums", emit_null: false)]
    property checksums : Array(Checksum)?

    @[JSON::Field(key: "homepage", emit_null: false)]
    property homepage : String?

    @[JSON::Field(key: "sourceInfo", emit_null: false)]
    property source_info : String?

    @[JSON::Field(key: "licenseConcluded")]
    property license_concluded : String

    @[JSON::Field(key: "licenseInfoFromFiles", emit_null: false)]
    property license_info_from_files : Array(String)?

    @[JSON::Field(key: "licenseDeclared")]
    property license_declared : String

    @[JSON::Field(key: "licenseComments", emit_null: false)]
    property license_comments : String?

    @[JSON::Field(key: "copyrightText")]
    property copyright_text : String

    @[JSON::Field(key: "summary", emit_null: false)]
    property summary : String?

    @[JSON::Field(key: "description", emit_null: false)]
    property description : String?

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    @[JSON::Field(key: "externalRefs", emit_null: false)]
    property external_refs : Array(ExternalRef)?

    @[JSON::Field(key: "attributionTexts", emit_null: false)]
    property attribution_texts : Array(String)?

    @[JSON::Field(key: "primaryPackagePurpose", emit_null: false)]
    property primary_package_purpose : PrimaryPackagePurpose?

    @[JSON::Field(key: "releaseDate", emit_null: false)]
    property release_date : String?

    @[JSON::Field(key: "builtDate", emit_null: false)]
    property built_date : String?

    @[JSON::Field(key: "validUntilDate", emit_null: false)]
    property valid_until_date : String?

    def initialize(@spdx_id : String, @name : String, @download_location : String,
                   @license_concluded : String, @license_declared : String,
                   @copyright_text : String)
    end
  end

  class PackageVerificationCode
    include JSON::Serializable

    @[JSON::Field(key: "packageVerificationCodeValue")]
    property value : String

    @[JSON::Field(key: "packageVerificationCodeExcludedFiles", emit_null: false)]
    property excluded_files : Array(String)?

    def initialize(@value : String, @excluded_files : Array(String)? = nil)
    end
  end
end
