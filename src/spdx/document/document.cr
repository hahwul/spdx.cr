require "json"

module Spdx
  class SpdxDocument
    include JSON::Serializable

    SPDX_ID_PATTERN = /^SPDXRef-[a-zA-Z0-9.\-]+$/
    URI_PATTERN     = /^https?:\/\/.+/
    CREATOR_PATTERN = /^(Tool|Organization|Person):\s*.+$/
    ISO8601_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/

    @[JSON::Field(key: "spdxVersion")]
    property spdx_version : String

    @[JSON::Field(key: "dataLicense")]
    property data_license : String

    @[JSON::Field(key: "SPDXID")]
    property spdx_id : String

    @[JSON::Field(key: "name")]
    property name : String

    @[JSON::Field(key: "documentNamespace")]
    property document_namespace : String

    @[JSON::Field(key: "creationInfo")]
    property creation_info : CreationInfo

    @[JSON::Field(key: "comment", emit_null: false)]
    property comment : String?

    @[JSON::Field(key: "externalDocumentRefs", emit_null: false)]
    property external_document_refs : Array(ExternalDocumentRef)?

    @[JSON::Field(key: "packages", emit_null: false)]
    property packages : Array(Package)?

    @[JSON::Field(key: "files", emit_null: false)]
    property files : Array(FileInfo)?

    @[JSON::Field(key: "snippets", emit_null: false)]
    property snippets : Array(Snippet)?

    @[JSON::Field(key: "relationships", emit_null: false)]
    property relationships : Array(Relationship)?

    @[JSON::Field(key: "annotations", emit_null: false)]
    property annotations : Array(Annotation)?

    @[JSON::Field(key: "hasExtractedLicensingInfos", emit_null: false)]
    property extracted_licensing_infos : Array(ExtractedLicensingInfo)?

    @[JSON::Field(key: "documentDescribes", emit_null: false)]
    property document_describes : Array(String)?

    def initialize(@spdx_version : String, @data_license : String,
                   @spdx_id : String, @name : String,
                   @document_namespace : String, @creation_info : CreationInfo)
    end

    def validate : Array(String)
      errors = [] of String

      # Document-level required fields
      errors << "spdxVersion is required" if spdx_version.empty?
      errors << "spdxVersion must be 'SPDX-2.3'" if !spdx_version.empty? && spdx_version != "SPDX-2.3"
      errors << "dataLicense must be 'CC0-1.0'" if data_license != "CC0-1.0"
      errors << "SPDXID must be 'SPDXRef-DOCUMENT'" if spdx_id != "SPDXRef-DOCUMENT"
      errors << "name is required" if name.empty?
      errors << "documentNamespace is required" if document_namespace.empty?
      errors << "documentNamespace must be a valid URI" if !document_namespace.empty? && !document_namespace.matches?(URI_PATTERN)

      # CreationInfo validation
      validate_creation_info(errors)

      # Package validation
      validate_packages(errors)

      # File validation
      validate_files(errors)

      # Snippet validation
      validate_snippets(errors)

      # Relationship validation
      validate_relationships(errors)

      errors
    end

    def valid? : Bool
      validate.empty?
    end

    private def validate_creation_info(errors : Array(String))
      ci = creation_info
      errors << "creationInfo.created is required" if ci.created.empty?
      errors << "creationInfo.created must be ISO 8601 format (YYYY-MM-DDThh:mm:ssZ)" if !ci.created.empty? && !ci.created.matches?(ISO8601_PATTERN)
      errors << "creationInfo.creators must not be empty" if ci.creators.empty?

      ci.creators.each_with_index do |creator, i|
        unless creator.matches?(CREATOR_PATTERN)
          errors << "creationInfo.creators[#{i}] must start with 'Tool:', 'Organization:', or 'Person:'"
        end
      end
    end

    private def validate_packages(errors : Array(String))
      if pkgs = packages
        pkgs.each_with_index do |pkg, i|
          prefix = "packages[#{i}]"
          errors << "#{prefix}.SPDXID is required" if pkg.spdx_id.empty?
          errors << "#{prefix}.SPDXID format invalid" if !pkg.spdx_id.empty? && !pkg.spdx_id.matches?(SPDX_ID_PATTERN)
          errors << "#{prefix}.name is required" if pkg.name.empty?
          errors << "#{prefix}.downloadLocation is required" if pkg.download_location.empty?

          # filesAnalyzed defaults to true; if true, packageVerificationCode is mandatory
          files_analyzed = pkg.files_analyzed.nil? || pkg.files_analyzed == true
          if files_analyzed && pkg.package_verification_code.nil?
            errors << "#{prefix}.packageVerificationCode is required when filesAnalyzed is true"
          end

          errors << "#{prefix}.licenseConcluded is required" if pkg.license_concluded.empty?
          errors << "#{prefix}.licenseDeclared is required" if pkg.license_declared.empty?
          errors << "#{prefix}.copyrightText is required" if pkg.copyright_text.empty?
        end
      end
    end

    private def validate_files(errors : Array(String))
      if file_list = files
        file_list.each_with_index do |f, i|
          prefix = "files[#{i}]"
          errors << "#{prefix}.SPDXID is required" if f.spdx_id.empty?
          errors << "#{prefix}.SPDXID format invalid" if !f.spdx_id.empty? && !f.spdx_id.matches?(SPDX_ID_PATTERN)
          errors << "#{prefix}.fileName is required" if f.file_name.empty?
          errors << "#{prefix}.licenseConcluded is required" if f.license_concluded.empty?
          errors << "#{prefix}.copyrightText is required" if f.copyright_text.empty?
        end
      end
    end

    private def validate_snippets(errors : Array(String))
      if snippet_list = snippets
        snippet_list.each_with_index do |s, i|
          prefix = "snippets[#{i}]"
          errors << "#{prefix}.SPDXID is required" if s.spdx_id.empty?
          errors << "#{prefix}.SPDXID format invalid" if !s.spdx_id.empty? && !s.spdx_id.matches?(SPDX_ID_PATTERN)
          errors << "#{prefix}.snippetFromFile is required" if s.snippet_from_file.empty?
          errors << "#{prefix}.ranges must not be empty" if s.ranges.empty?
          errors << "#{prefix}.licenseConcluded is required" if s.license_concluded.empty?
          errors << "#{prefix}.copyrightText is required" if s.copyright_text.empty?
        end
      end
    end

    private def validate_relationships(errors : Array(String))
      if rels = relationships
        has_describes = rels.any? { |r| r.relationship_type == RelationshipType::DESCRIBES }
        errors << "document must have at least one DESCRIBES relationship" unless has_describes

        rels.each_with_index do |rel, i|
          prefix = "relationships[#{i}]"
          errors << "#{prefix}.spdxElementId is required" if rel.spdx_element_id.empty?
          errors << "#{prefix}.relatedSpdxElement is required" if rel.related_spdx_element.empty?
        end
      else
        errors << "document must have at least one DESCRIBES relationship"
      end
    end
  end
end
