require "json"

module Spdx
  class SpdxDocument
    include JSON::Serializable

    # `\A`/`\z`, not `^`/`$`: PCRE's `$` also matches before a trailing "\n".
    SPDX_ID_PATTERN = /\ASPDXRef-[a-zA-Z0-9.\-]+\z/
    URI_PATTERN     = /^https?:\/\/.+/
    CREATOR_PATTERN = /\A(Tool|Organization|Person):\s*.+\z/
    # The SPDX 2.3 JSON schema's date-time pattern (month 01-12, day 01-31,
    # hour 00-23, 23:59:60 for a leap second), plus optional fractional
    # seconds.
    ISO8601_PATTERN = /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T(([01]\d|2[0-3]):[0-5]\d:[0-5]\d|23:59:60)(\.\d+)?Z\z/
    private ISO8601_MESSAGE = "must be ISO 8601 format (YYYY-MM-DDThh:mm:ssZ)"
    # Checksum values are hexadecimal (SPDX 2.3 §8.4; the JSON schema's
    # `checksumValue` pattern).
    HEX_PATTERN = /\A[0-9a-fA-F]+\z/
    # `DocumentRef-[idstring]`, where §6.6's idstring also allows "+".
    EXTERNAL_DOCUMENT_ID_PATTERN = /\ADocumentRef-[A-Za-z0-9.\-+]+\z/
    # `"LicenseRef-"[idstring]` where idstring is letters, numbers, "." and
    # "-" (SPDX 2.3 §10.1).
    LICENSE_REF_PATTERN = Expression::Validator::LICENSE_REF_PATTERN
    # Accepted on input for backwards compatibility, but not in SPDX 2.3
    # (clause 11.1, Table 68; the 2.3 JSON schema's relationshipType enum).
    NON_SPDX_2_3_RELATIONSHIP_TYPES = {
      RelationshipType::GENERATED_FROM_COPY, RelationshipType::GENERATES_COPY,
      RelationshipType::VARIANT_DISTRIBUTION_OF, RelationshipType::SECURITY_FIX_FOR,
      RelationshipType::AFFECTS,
    }

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

    # Moves each document-level annotation whose `spdx_element_id` names a
    # local package, file or snippet into that element's `annotations`, the
    # SPDX 2.3 JSON schema's nesting (it has no `spdxElementId` on
    # annotations). Annotations of the document itself or of external
    # elements stay at document level.
    def nest_element_annotations : Nil
      return unless anns = annotations
      owners = {} of String => Package | FileInfo | Snippet
      packages.try &.each { |e| owners[e.spdx_id] = e }
      files.try &.each { |e| owners[e.spdx_id] = e }
      snippets.try &.each { |e| owners[e.spdx_id] = e }

      kept = anns.reject do |ann|
        next false unless (id = ann.spdx_element_id) && (owner = owners[id]?)
        (owner.annotations ||= [] of Annotation) << ann
        true
      end
      self.annotations = kept.empty? ? nil : kept
    end

    # Legacy JSON (and tag-value converted by older tools) may carry
    # element annotations at document level with `spdxElementId`.
    def after_initialize
      nest_element_annotations
    end

    def validate : Array(String)
      errors = [] of String

      # The JSON and tag-value parsers reject invalid UTF-8, but a document
      # built in code (or via `from_json`) can still carry it.
      # ponytail: serializes the whole document once per call; walk the
      # string fields instead if validating huge SBOMs gets memory-bound.
      errors << "document contains invalid UTF-8 (SPDX documents must be UTF-8)" unless to_json.valid_encoding?

      # Document-level required fields
      errors << "spdxVersion is required" if spdx_version.empty?
      errors << "spdxVersion must be 'SPDX-2.3'" if !spdx_version.empty? && spdx_version != "SPDX-2.3"
      errors << "dataLicense must be 'CC0-1.0'" if data_license != "CC0-1.0"
      errors << "SPDXID must be 'SPDXRef-DOCUMENT'" if spdx_id != "SPDXRef-DOCUMENT"
      errors << "name is required" if name.empty?
      errors << "documentNamespace is required" if document_namespace.empty?
      errors << "documentNamespace must be a valid URI" if !document_namespace.empty? && !utf8_match?(document_namespace, URI_PATTERN)
      # SPDX 2.3 §6.5: the namespace URI must not carry a fragment, because
      # '#' separates the namespace from an element identifier.
      errors << "documentNamespace must not contain a '#' fragment delimiter" if document_namespace.includes?('#')

      # CreationInfo validation
      validate_creation_info(errors)

      validate_external_document_refs(errors)
      validate_annotations("annotations", annotations, errors)
      validate_annotation_subjects(errors)

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

      # Other Licensing Information Detected validation
      validate_extracted_licensing_infos(errors)

      errors
    end

    def valid? : Bool
      validate.empty?
    end

    # `matches?` raises ArgumentError on invalid UTF-8; such a value is
    # reported by the document-level UTF-8 check and fails the format check.
    private def utf8_match?(value : String, pattern : Regex) : Bool
      value.valid_encoding? && value.matches?(pattern)
    end

    private def validate_creation_info(errors : Array(String))
      ci = creation_info
      errors << "creationInfo.created is required" if ci.created.empty?
      validate_date("creationInfo.created", ci.created, errors) unless ci.created.empty?
      errors << "creationInfo.creators must not be empty" if ci.creators.empty?

      ci.creators.each_with_index do |creator, i|
        unless utf8_match?(creator, CREATOR_PATTERN)
          errors << "creationInfo.creators[#{i}] must start with 'Tool:', 'Organization:', or 'Person:'"
        end
      end
    end

    private def validate_packages(errors : Array(String))
      if pkgs = packages
        pkgs.each_with_index do |pkg, i|
          prefix = "packages[#{i}]"
          errors << "#{prefix}.SPDXID is required" if pkg.spdx_id.empty?
          errors << "#{prefix}.SPDXID format invalid" if !pkg.spdx_id.empty? && !utf8_match?(pkg.spdx_id, SPDX_ID_PATTERN)
          errors << "#{prefix}.name is required" if pkg.name.empty?
          errors << "#{prefix}.downloadLocation is required" if pkg.download_location.empty?

          # packageVerificationCode is optional, but must be omitted when
          # filesAnalyzed is false (SPDX 2.3 §7.9, Table 21).
          if pkg.files_analyzed == false && pkg.package_verification_code
            errors << "#{prefix}.packageVerificationCode must be omitted when filesAnalyzed is false"
          end
          # Likewise licenseInfoFromFiles (§7.14, Table 26), and such a package
          # "shall not contain any files" (§7.8).
          if pkg.files_analyzed == false
            errors << "#{prefix}.licenseInfoFromFiles must be omitted when filesAnalyzed is false" if pkg.license_info_from_files
            errors << "#{prefix}.hasFiles must be omitted when filesAnalyzed is false" if pkg.has_files
          end

          validate_license_expression("#{prefix}.licenseConcluded", pkg.license_concluded, errors)
          validate_license_expression("#{prefix}.licenseDeclared", pkg.license_declared, errors)
          # §7.25-7.27: same format as `created`.
          pkg.release_date.try { |d| validate_date("#{prefix}.releaseDate", d, errors) }
          pkg.built_date.try { |d| validate_date("#{prefix}.builtDate", d, errors) }
          pkg.valid_until_date.try { |d| validate_date("#{prefix}.validUntilDate", d, errors) }
          validate_checksums(prefix, pkg.checksums, errors)
          validate_annotations("#{prefix}.annotations", pkg.annotations, errors)
          if infos = pkg.license_info_from_files
            infos.each_with_index do |li, j|
              validate_license_expression("#{prefix}.licenseInfoFromFiles[#{j}]", li, errors)
            end
          end
        end
      end
    end

    # Validates a single SPDX license-expression field. Absent values are
    # allowed (SPDX 2.3 §7.13/§7.15/§8.5/§9.6: cardinality 0..1, an omitted
    # field implies NOASSERTION); present values must parse and reference
    # known licenses/exceptions (or be the reserved values NONE / NOASSERTION).
    private def validate_license_expression(field : String, value : String?, errors : Array(String))
      return if value.nil?
      ast = Spdx.parse(value)
      Expression::Validator.validate(ast).errors.each { |e| errors << "#{field}: #{e}" }
      # Like an element reference, `DocumentRef-x:LicenseRef-y` names an
      # external document, which must be declared (SPDX 2.3 §6.6).
      refs = Set(String).new
      collect_document_refs(ast, refs)
      unless refs.empty?
        declared = external_document_ref_ids
        refs.each do |doc_ref|
          errors << "#{field}: #{doc_ref} is not declared in externalDocumentRefs" unless declared.includes?(doc_ref)
        end
      end
    rescue ex : ParseError
      errors << "#{field}: invalid SPDX license expression (#{ex.message})"
    end

    private def validate_files(errors : Array(String))
      if file_list = files
        file_list.each_with_index do |f, i|
          prefix = "files[#{i}]"
          errors << "#{prefix}.SPDXID is required" if f.spdx_id.empty?
          errors << "#{prefix}.SPDXID format invalid" if !f.spdx_id.empty? && !utf8_match?(f.spdx_id, SPDX_ID_PATTERN)
          errors << "#{prefix}.fileName is required" if f.file_name.empty?
          # SPDX 2.3 §8.4, Table 39: a SHA1 checksum is mandatory (1..1).
          unless f.checksums.try &.any?(&.algorithm.sha1?)
            errors << "#{prefix}.checksums must include a SHA1 checksum"
          end

          validate_checksums(prefix, f.checksums, errors)
          validate_annotations("#{prefix}.annotations", f.annotations, errors)

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
          errors << "#{prefix}.SPDXID format invalid" if !s.spdx_id.empty? && !utf8_match?(s.spdx_id, SPDX_ID_PATTERN)
          errors << "#{prefix}.snippetFromFile is required" if s.snippet_from_file.empty?
          errors << "#{prefix}.ranges must not be empty" if s.ranges.empty?
          validate_annotations("#{prefix}.annotations", s.annotations, errors)

          validate_license_expression("#{prefix}.licenseConcluded", s.license_concluded, errors)
          if infos = s.license_info_in_snippets
            infos.each_with_index do |li, j|
              validate_license_expression("#{prefix}.licenseInfoInSnippets[#{j}]", li, errors)
            end
          end
        end
      end
    end

    private def validate_date(field : String, value : String, errors : Array(String))
      errors << "#{field} #{ISO8601_MESSAGE}" unless utf8_match?(value, ISO8601_PATTERN) && calendar_date?(value)
    end

    # The pattern bounds each component; this rejects dates such as
    # 2023-02-29 or 2024-04-31. Only the date is parsed, so a leap second
    # (23:59:60) is not rejected.
    private def calendar_date?(value : String) : Bool
      Time.parse_utc(value[0, 10], "%F")
      true
    rescue Time::Format::Error | ArgumentError
      false
    end

    private def validate_checksums(prefix : String, checksums : Array(Checksum)?, errors : Array(String))
      checksums.try &.each_with_index do |c, i|
        validate_checksum_value("#{prefix}.checksums[#{i}]", c, errors)
      end
    end

    private def validate_checksum_value(field : String, checksum : Checksum, errors : Array(String))
      errors << "#{field}.checksumValue must be hexadecimal" unless utf8_match?(checksum.value, HEX_PATTERN)
    end

    # SPDX 2.3 clause 12: annotator, date and comment are each mandatory
    # for an annotation; annotator has the creator format, date the
    # `created` format.
    private def validate_annotations(prefix : String, anns : Array(Annotation)?, errors : Array(String))
      anns.try &.each_with_index do |ann, i|
        p = "#{prefix}[#{i}]"
        if ann.annotator.empty?
          errors << "#{p}.annotator is required"
        elsif !utf8_match?(ann.annotator, CREATOR_PATTERN)
          errors << "#{p}.annotator must start with 'Tool:', 'Organization:', or 'Person:'"
        end
        if ann.annotation_date.empty?
          errors << "#{p}.annotationDate is required"
        else
          validate_date("#{p}.annotationDate", ann.annotation_date, errors)
        end
        errors << "#{p}.comment is required" if ann.comment.empty?
      end
    end

    # Element annotations were nested into their element when parsed, so a
    # document-level `SPDXREF` must name the document itself or a declared
    # external element (§12.4); otherwise it is lost when written as JSON.
    private def validate_annotation_subjects(errors : Array(String))
      annotations.try &.each_with_index do |ann, i|
        next unless id = ann.spdx_element_id
        next if id == spdx_id || valid_element_reference?(id, defined_spdx_ids, external_document_ref_ids)
        errors << "annotations[#{i}].SPDXREF references undefined element '#{id}'"
      end
    end

    # SPDX 2.3 §6.6: `DocumentRef-[idstring] [SPDX document URI] [Checksum]`,
    # the idstring unique within the document and the URI a namespace (§6.5).
    private def validate_external_document_refs(errors : Array(String))
      seen = Set(String).new
      external_document_refs.try &.each_with_index do |ref, i|
        prefix = "externalDocumentRefs[#{i}]"
        id = ref.external_document_id
        if !utf8_match?(id, EXTERNAL_DOCUMENT_ID_PATTERN)
          errors << "#{prefix}.externalDocumentId must be of the form 'DocumentRef-[idstring]'"
        elsif !seen.add?(id)
          errors << "#{prefix}.externalDocumentId duplicates '#{id}'"
        end
        errors << "#{prefix}.spdxDocument must be a valid URI" unless utf8_match?(ref.spdx_document, URI_PATTERN)
        errors << "#{prefix}.spdxDocument must not contain a '#' fragment delimiter" if ref.spdx_document.includes?('#')
        validate_checksum_value("#{prefix}.checksum", ref.checksum, errors)
      end
    end

    private def collect_document_refs(node : Expression::Node, refs : Set(String)) : Nil
      case node
      when Expression::LicenseRefNode    then node.document_ref.try { |d| refs << d }
      when Expression::WithExceptionNode then collect_document_refs(node.license, refs)
      when Expression::CompoundNode
        collect_document_refs(node.left, refs)
        collect_document_refs(node.right, refs)
      end
    end

    # Validates the `hasExtractedLicensingInfos` entries (SPDX 2.3 clause 10):
    # each licenseId must be a well-formed `LicenseRef-` identifier, must be
    # unique within the document, and must carry the extracted license text.
    private def validate_extracted_licensing_infos(errors : Array(String))
      infos = extracted_licensing_infos
      return if infos.nil?

      seen = Set(String).new
      infos.each_with_index do |info, i|
        prefix = "hasExtractedLicensingInfos[#{i}]"
        if info.license_id.empty?
          errors << "#{prefix}.licenseId is required"
        elsif !utf8_match?(info.license_id, LICENSE_REF_PATTERN)
          errors << "#{prefix}.licenseId must be of the form 'LicenseRef-[idstring]'"
        elsif !seen.add?(info.license_id)
          errors << "#{prefix}.licenseId duplicates '#{info.license_id}'"
        end
        errors << "#{prefix}.extractedText is required" if info.extracted_text.empty?
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
        if NON_SPDX_2_3_RELATIONSHIP_TYPES.includes?(rel.relationship_type)
          errors << "#{prefix}.relationshipType '#{rel.relationship_type}' is not an SPDX 2.3 relationship type"
        end
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
