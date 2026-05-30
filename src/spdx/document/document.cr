require "json"

module Spdx
  class SpdxDocument
    include JSON::Serializable

    SPDX_ID_PATTERN = /^SPDXRef-[a-zA-Z0-9.\-]+$/
    URI_PATTERN     = /^https?:\/\/.+/
    CREATOR_PATTERN = /^(Tool|Organization|Person):\s*.+$/
    ISO8601_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/

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

      # SPDXID uniqueness across the document, packages, files, snippets
      validate_spdx_id_uniqueness(errors)

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

          validate_license_expression("#{prefix}.licenseConcluded", pkg.license_concluded, errors)
          validate_license_expression("#{prefix}.licenseDeclared", pkg.license_declared, errors)
          if infos = pkg.license_info_from_files
            infos.each_with_index do |li, j|
              validate_license_expression("#{prefix}.licenseInfoFromFiles[#{j}]", li, errors)
            end
          end
        end
      end
    end

    # Validates a single SPDX license-expression field. Empty values are
    # ignored here (handled by the field-required checks); non-empty values
    # must parse and reference known licenses/exceptions (or be the reserved
    # values NONE / NOASSERTION).
    private def validate_license_expression(field : String, value : String, errors : Array(String))
      return if value.empty?
      result = Spdx.validate_expression(value)
      result.errors.each { |e| errors << "#{field}: #{e}" }
    rescue ex : ParseError
      errors << "#{field}: invalid SPDX license expression (#{ex.message})"
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

          validate_license_expression("#{prefix}.licenseConcluded", f.license_concluded, errors)
          if infos = f.license_info_in_files
            infos.each_with_index do |li, j|
              validate_license_expression("#{prefix}.licenseInfoInFiles[#{j}]", li, errors)
            end
          end
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

          validate_license_expression("#{prefix}.licenseConcluded", s.license_concluded, errors)
          if infos = s.license_info_in_snippets
            infos.each_with_index do |li, j|
              validate_license_expression("#{prefix}.licenseInfoInSnippets[#{j}]", li, errors)
            end
          end
        end
      end
    end

    private def validate_relationships(errors : Array(String))
      defined = defined_spdx_ids
      external = external_document_ref_ids

      # The document must declare what it describes — via at least one
      # DESCRIBES relationship OR via the top-level `documentDescribes`
      # array (SPDX 2.3 permits either).
      has_describes_rel = relationships.try(&.any? { |r| r.relationship_type == RelationshipType::DESCRIBES })
      dd = document_describes
      has_document_describes = !dd.nil? && !dd.empty?
      unless has_describes_rel || has_document_describes
        errors << "document must declare what it describes (a DESCRIBES relationship or documentDescribes)"
      end

      # Every documentDescribes entry must reference a defined element.
      document_describes.try &.each_with_index do |ref, i|
        unless valid_element_reference?(ref, defined, external)
          errors << "documentDescribes[#{i}] references undefined element '#{ref}'"
        end
      end

      relationships.try &.each_with_index do |rel, i|
        prefix = "relationships[#{i}]"
        if rel.spdx_element_id.empty?
          errors << "#{prefix}.spdxElementId is required"
        elsif !valid_element_reference?(rel.spdx_element_id, defined, external)
          errors << "#{prefix}.spdxElementId references undefined element '#{rel.spdx_element_id}'"
        end

        if rel.related_spdx_element.empty?
          errors << "#{prefix}.relatedSpdxElement is required"
        elsif !valid_element_reference?(rel.related_spdx_element, defined, external)
          errors << "#{prefix}.relatedSpdxElement references undefined element '#{rel.related_spdx_element}'"
        end
      end
    end

    # All SPDXIDs defined in this document (the document itself plus every
    # package, file, and snippet).
    private def defined_spdx_ids : Set(String)
      ids = Set(String).new
      ids << spdx_id unless spdx_id.empty?
      packages.try &.each { |p| ids << p.spdx_id unless p.spdx_id.empty? }
      files.try &.each { |f| ids << f.spdx_id unless f.spdx_id.empty? }
      snippets.try &.each { |s| ids << s.spdx_id unless s.spdx_id.empty? }
      ids
    end

    # The DocumentRef-* identifiers declared in externalDocumentRefs.
    private def external_document_ref_ids : Set(String)
      ids = Set(String).new
      external_document_refs.try &.each do |r|
        ids << r.external_document_id unless r.external_document_id.empty?
      end
      ids
    end

    # Whether an SPDX element reference is resolvable: the reserved values
    # NONE/NOASSERTION, a locally-defined SPDXID, or an external reference of
    # the form `DocumentRef-xxx:SPDXRef-yyy` whose DocumentRef-xxx is declared
    # in externalDocumentRefs.
    private def valid_element_reference?(ref : String, defined : Set(String), external : Set(String)) : Bool
      return true if ref == "NONE" || ref == "NOASSERTION"
      return true if defined.includes?(ref)
      if ref.includes?(':')
        doc_ref = ref.partition(':')[0]
        return external.includes?(doc_ref)
      end
      false
    end

    private def validate_spdx_id_uniqueness(errors : Array(String))
      seen = Set(String).new
      reported = Set(String).new
      check = ->(id : String, label : String) do
        return if id.empty?
        if seen.includes?(id) && !reported.includes?(id)
          errors << "duplicate SPDXID '#{id}' (#{label})"
          reported << id
        end
        seen << id
      end

      check.call(spdx_id, "document")
      packages.try &.each_with_index { |p, i| check.call(p.spdx_id, "packages[#{i}]") }
      files.try &.each_with_index { |f, i| check.call(f.spdx_id, "files[#{i}]") }
      snippets.try &.each_with_index { |s, i| check.call(s.spdx_id, "snippets[#{i}]") }
    end
  end
end
