module Spdx
  module Format
    module TagValue
      class Parser
        enum Section
          Document
          Package
          File
          Snippet
          License
          Relationship
          Annotation
          Review
        end

        @lines : Array(String)
        @current_section : Section = Section::Document
        @in_multiline : Bool = false
        @multiline_tag : String = ""
        @multiline_value : String::Builder = String::Builder.new
        @doc_fields : Hash(String, String)
        @doc_multi_fields : Hash(String, Array(String))
        @packages : Array(Hash(String, String | Array(String)))
        @file_infos : Array(Hash(String, String | Array(String)))
        @snippets : Array(Hash(String, String | Array(String)))
        @relationships : Array({String, String, String, String?})
        @annotations : Array(Hash(String, String))
        @extracted_licenses : Array(Hash(String, String | Array(String)))
        @external_doc_refs : Array({String, String, String, String})
        @current_pkg : Hash(String, String | Array(String))? = nil
        @current_file : Hash(String, String | Array(String))? = nil
        @current_snippet : Hash(String, String | Array(String))? = nil
        @current_annotation : Hash(String, String)? = nil
        @current_extracted : Hash(String, String | Array(String))? = nil

        def self.parse(input : String) : SpdxDocument
          new(input).parse
        end

        def self.parse_file(path : String) : SpdxDocument
          parse(::File.read(path))
        end

        def initialize(input : String)
          @lines = input.lines
          @doc_fields = {} of String => String
          @doc_multi_fields = {} of String => Array(String)
          @packages = [] of Hash(String, String | Array(String))
          @file_infos = [] of Hash(String, String | Array(String))
          @snippets = [] of Hash(String, String | Array(String))
          @relationships = [] of {String, String, String, String?}
          @annotations = [] of Hash(String, String)
          @extracted_licenses = [] of Hash(String, String | Array(String))
          @external_doc_refs = [] of {String, String, String, String}
        end

        def parse : SpdxDocument
          @lines.each do |line|
            if @in_multiline
              handle_multiline(line)
            else
              parse_line(line.strip)
            end
          end

          flush_section
          build_document
        end

        private def parse_line(line : String)
          return if line.empty? || line.starts_with?('#')

          # Check for tag: value format
          if m = line.match(/^([A-Za-z]+):\s*(.*)$/)
            tag = m[1]
            value = m[2].strip

            # Check for multiline start
            if value.starts_with?("<text>")
              @in_multiline = true
              @multiline_tag = tag
              @multiline_value = String::Builder.new
              text_start = value[6..]
              if text_start.ends_with?("</text>")
                @in_multiline = false
                set_field(tag, text_start[...-7])
              else
                @multiline_value << text_start
              end
              return
            end

            handle_tag(tag, value)
          end
        end

        private def handle_multiline(line : String)
          if line.strip.ends_with?("</text>")
            stripped = line.strip[...-7]
            @multiline_value << "\n" unless @multiline_value.empty?
            @multiline_value << stripped unless stripped.empty?
            @in_multiline = false
            set_field(@multiline_tag, @multiline_value.to_s)
          else
            @multiline_value << "\n" unless @multiline_value.empty?
            @multiline_value << line
          end
        end

        private def handle_tag(tag : String, value : String)
          case tag
          when "SPDXVersion"
            @doc_fields["SPDXVersion"] = value
          when "DataLicense"
            @doc_fields["DataLicense"] = value
          when "SPDXID"
            case @current_section
            when .document?
              if @doc_fields.has_key?("SPDXID")
                # Must be a new section element, but with just SPDXID
                # it could be package, file, or snippet - defer to next tag
              end
              @doc_fields["SPDXID"] = value
            when .package?
              set_field("SPDXID", value)
            when .file?
              set_field("SPDXID", value)
            when .snippet?
              set_field("SPDXID", value)
            else
              set_field("SPDXID", value)
            end
          when "DocumentName"
            @doc_fields["DocumentName"] = value
          when "DocumentNamespace"
            @doc_fields["DocumentNamespace"] = value
          when "DocumentComment"
            @doc_fields["DocumentComment"] = value
          when "ExternalDocumentRef"
            parse_external_doc_ref(value)
          when "Creator"
            (@doc_multi_fields["Creator"] ||= [] of String) << value
          when "Created"
            @doc_fields["Created"] = value
          when "CreatorComment"
            @doc_fields["CreatorComment"] = value
          when "LicenseListVersion"
            @doc_fields["LicenseListVersion"] = value
          when "PackageName"
            flush_section
            @current_section = Section::Package
            @current_pkg = {"PackageName" => value} of String => String | Array(String)
          when "FileName"
            flush_section
            @current_section = Section::File
            @current_file = {"FileName" => value} of String => String | Array(String)
          when "SnippetSPDXID"
            flush_section
            @current_section = Section::Snippet
            @current_snippet = {"SPDXID" => value} of String => String | Array(String)
          when "SnippetFromFileSPDXID"
            set_field("SnippetFromFileSPDXID", value)
          when "SnippetByteRange", "SnippetLineRange"
            set_field(tag, value)
          when "SnippetName"
            set_field("SnippetName", value)
          when "SnippetLicenseConcluded"
            set_field("SnippetLicenseConcluded", value)
          when "SnippetCopyrightText"
            set_field("SnippetCopyrightText", value)
          when "SnippetLicenseComments"
            set_field("SnippetLicenseComments", value)
          when "LicenseInfoInSnippet"
            append_field("LicenseInfoInSnippet", value)
          when "Relationship"
            parse_relationship(value)
          when "RelationshipComment"
            # Attach comment to last relationship
            if !@relationships.empty?
              last = @relationships.last
              @relationships[-1] = {last[0], last[1], last[2], value}
            end
          when "Annotator"
            flush_section
            @current_section = Section::Annotation
            @current_annotation = {"Annotator" => value} of String => String
          when "AnnotationDate"
            if ann = @current_annotation
              ann["AnnotationDate"] = value
            end
          when "AnnotationComment"
            if ann = @current_annotation
              ann["AnnotationComment"] = value
            end
          when "AnnotationType"
            if ann = @current_annotation
              ann["AnnotationType"] = value
            end
          when "SPDXREF"
            if ann = @current_annotation
              ann["SPDXREF"] = value
            end
          when "LicenseID"
            flush_section
            @current_section = Section::License
            @current_extracted = {"LicenseID" => value} of String => String | Array(String)
          when "ExtractedText"
            set_field("ExtractedText", value)
          when "LicenseName"
            set_field("LicenseName", value)
          when "LicenseCrossReference"
            append_field("LicenseCrossReference", value)
          when "LicenseComment"
            set_field("LicenseComment", value)
          when "PackageChecksum", "FileChecksum"
            append_field(tag, value)
          when "FileType"
            append_field("FileType", value)
          when "FileContributor"
            append_field("FileContributor", value)
          when "ExternalRef"
            append_field("ExternalRef", value)
          when "PackageLicenseInfoFromFiles"
            append_field("PackageLicenseInfoFromFiles", value)
          when "LicenseInfoInFile"
            append_field("LicenseInfoInFile", value)
          when "PackageAttributionText"
            append_field("PackageAttributionText", value)
          when "FileAttributionText"
            append_field("FileAttributionText", value)
          when "SnippetAttributionText"
            append_field("SnippetAttributionText", value)
          else
            set_field(tag, value)
          end
        end

        private def set_field(tag : String, value : String)
          case @current_section
          when .package?
            if pkg = @current_pkg
              pkg[tag] = value
            end
          when .file?
            if f = @current_file
              f[tag] = value
            end
          when .snippet?
            if s = @current_snippet
              s[tag] = value
            end
          when .license?
            if e = @current_extracted
              e[tag] = value
            end
          when .annotation?
            if ann = @current_annotation
              ann[tag] = value
            end
          else
            @doc_fields[tag] = value
          end
        end

        private def append_field(tag : String, value : String)
          case @current_section
          when .package?
            if pkg = @current_pkg
              existing = pkg[tag]?
              case existing
              when Array(String)
                existing << value
              when String
                pkg[tag] = [existing, value] of String
              else
                pkg[tag] = [value] of String
              end
            end
          when .file?
            if f = @current_file
              existing = f[tag]?
              case existing
              when Array(String)
                existing << value
              when String
                f[tag] = [existing, value] of String
              else
                f[tag] = [value] of String
              end
            end
          when .snippet?
            if s = @current_snippet
              existing = s[tag]?
              case existing
              when Array(String)
                existing << value
              when String
                s[tag] = [existing, value] of String
              else
                s[tag] = [value] of String
              end
            end
          when .license?
            if e = @current_extracted
              existing = e[tag]?
              case existing
              when Array(String)
                existing << value
              when String
                e[tag] = [existing, value] of String
              else
                e[tag] = [value] of String
              end
            end
          end
        end

        private def parse_relationship(value : String)
          parts = value.split(/\s+/, 3)
          if parts.size >= 3
            @relationships << {parts[0], parts[1], parts[2], nil}
          end
        end

        private def parse_external_doc_ref(value : String)
          parts = value.split(/\s+/)
          if parts.size >= 3
            algo_value = parts[2].split(":")
            if algo_value.size == 2
              @external_doc_refs << {parts[0], parts[1], algo_value[0], algo_value[1]}
            end
          end
        end

        private def flush_section
          case @current_section
          when .package?
            if pkg = @current_pkg
              @packages << pkg
              @current_pkg = nil
            end
          when .file?
            if f = @current_file
              @file_infos << f
              @current_file = nil
            end
          when .snippet?
            if s = @current_snippet
              @snippets << s
              @current_snippet = nil
            end
          when .annotation?
            if ann = @current_annotation
              @annotations << ann
              @current_annotation = nil
            end
          when .license?
            if e = @current_extracted
              @extracted_licenses << e
              @current_extracted = nil
            end
          end
        end

        private def build_document : SpdxDocument
          creators = @doc_multi_fields["Creator"]? || [] of String
          creation_info = CreationInfo.new(
            created: @doc_fields["Created"]? || "",
            creators: creators,
            license_list_version: @doc_fields["LicenseListVersion"]?,
            comment: @doc_fields["CreatorComment"]?
          )

          doc = SpdxDocument.new(
            spdx_version: @doc_fields["SPDXVersion"]? || "",
            data_license: @doc_fields["DataLicense"]? || "",
            spdx_id: @doc_fields["SPDXID"]? || "SPDXRef-DOCUMENT",
            name: @doc_fields["DocumentName"]? || "",
            document_namespace: @doc_fields["DocumentNamespace"]? || "",
            creation_info: creation_info
          )

          doc.comment = @doc_fields["DocumentComment"]?

          unless @external_doc_refs.empty?
            doc.external_document_refs = @external_doc_refs.map do |ref|
              ExternalDocumentRef.new(
                external_document_id: ref[0],
                spdx_document: ref[1],
                checksum: Checksum.new(
                  algorithm: ChecksumAlgorithm.from_string(ref[2]),
                  value: ref[3]
                )
              )
            end
          end

          unless @packages.empty?
            doc.packages = @packages.map { |p| build_package(p) }
          end

          unless @file_infos.empty?
            doc.files = @file_infos.map { |f| build_file(f) }
          end

          unless @snippets.empty?
            doc.snippets = @snippets.map { |s| build_snippet(s) }
          end

          unless @relationships.empty?
            doc.relationships = @relationships.map do |r|
              Relationship.new(
                spdx_element_id: r[0],
                relationship_type: RelationshipType.from_string(r[1]),
                related_spdx_element: r[2],
                comment: r[3]
              )
            end
          end

          unless @annotations.empty?
            doc.annotations = @annotations.map do |a|
              Annotation.new(
                annotation_date: a["AnnotationDate"]? || "",
                annotation_type: a["AnnotationType"]? == "REVIEW" ? AnnotationType::REVIEW : AnnotationType::OTHER,
                annotator: a["Annotator"]? || "",
                comment: a["AnnotationComment"]? || "",
                spdx_element_id: a["SPDXREF"]?
              )
            end
          end

          unless @extracted_licenses.empty?
            doc.extracted_licensing_infos = @extracted_licenses.map do |e|
              see_alsos = case v = e["LicenseCrossReference"]?
                          when Array(String) then v
                          when String        then [v]
                          else                    nil
                          end

              ExtractedLicensingInfo.new(
                license_id: str_field(e, "LicenseID"),
                extracted_text: str_field(e, "ExtractedText"),
                name: e["LicenseName"]?.as?(String),
                comment: e["LicenseComment"]?.as?(String),
                see_alsos: see_alsos
              )
            end
          end

          doc
        end

        private def str_field(h : Hash(String, String | Array(String)), key : String) : String
          case v = h[key]?
          when String then v
          else             ""
          end
        end

        private def build_package(p : Hash(String, String | Array(String))) : Package
          pkg = Package.new(
            spdx_id: str_field(p, "SPDXID"),
            name: str_field(p, "PackageName"),
            download_location: str_field(p, "PackageDownloadLocation"),
            license_concluded: str_field(p, "PackageLicenseConcluded"),
            license_declared: str_field(p, "PackageLicenseDeclared"),
            copyright_text: str_field(p, "PackageCopyrightText")
          )
          pkg.version_info = p["PackageVersion"]?.as?(String)
          pkg.package_file_name = p["PackageFileName"]?.as?(String)
          pkg.supplier = p["PackageSupplier"]?.as?(String)
          pkg.originator = p["PackageOriginator"]?.as?(String)
          pkg.homepage = p["PackageHomePage"]?.as?(String)
          pkg.source_info = p["PackageSourceInfo"]?.as?(String)
          pkg.license_comments = p["PackageLicenseComments"]?.as?(String)
          pkg.summary = p["PackageSummary"]?.as?(String)
          pkg.description = p["PackageDescription"]?.as?(String)
          pkg.comment = p["PackageComment"]?.as?(String)

          if fa = p["FilesAnalyzed"]?.as?(String)
            pkg.files_analyzed = fa.downcase == "true"
          end

          if checksums = build_checksums(p)
            pkg.checksums = checksums
          end

          if li = p["PackageLicenseInfoFromFiles"]?
            pkg.license_info_from_files = case li
                                          when Array(String) then li
                                          when String        then [li]
                                          else                    nil
                                          end
          end

          if refs = build_external_refs(p)
            pkg.external_refs = refs
          end

          if at = p["PackageAttributionText"]?
            pkg.attribution_texts = case at
                                    when Array(String) then at
                                    when String        then [at]
                                    else                    nil
                                    end
          end

          if pp = p["PrimaryPackagePurpose"]?.as?(String)
            pkg.primary_package_purpose = PrimaryPackagePurpose.from_string(pp)
          end

          if vc = p["PackageVerificationCode"]?.as?(String)
            parts = vc.split(/\s*\(excludes:\s*/, 2)
            excluded = if parts.size > 1
                         [parts[1].rstrip(')')]
                       else
                         nil
                       end
            pkg.package_verification_code = PackageVerificationCode.new(parts[0].strip, excluded)
          end

          pkg
        end

        private def build_file(f : Hash(String, String | Array(String))) : FileInfo
          fi = FileInfo.new(
            spdx_id: str_field(f, "SPDXID"),
            file_name: str_field(f, "FileName"),
            license_concluded: str_field(f, "LicenseConcluded"),
            copyright_text: str_field(f, "FileCopyrightText")
          )

          if ft = f["FileType"]?
            values = case ft
                     when Array(String) then ft
                     when String        then [ft]
                     else                    nil
                     end
            if values
              fi.file_types = values.map { |v| FileType.from_string(v) }
            end
          end

          if li = f["LicenseInfoInFile"]?
            fi.license_info_in_files = case li
                                       when Array(String) then li
                                       when String        then [li]
                                       else                    nil
                                       end
          end

          fi.comment = f["FileComment"]?.as?(String)
          fi.notice_text = f["FileNotice"]?.as?(String)

          if fc = f["FileContributor"]?
            fi.file_contributors = case fc
                                   when Array(String) then fc
                                   when String        then [fc]
                                   else                    nil
                                   end
          end

          if at = f["FileAttributionText"]?
            fi.attribution_texts = case at
                                   when Array(String) then at
                                   when String        then [at]
                                   else                    nil
                                   end
          end

          if checksums = build_checksums(f)
            fi.checksums = checksums
          end

          fi
        end

        private def build_snippet(s : Hash(String, String | Array(String))) : Snippet
          ranges = [] of SnippetRange

          if br = s["SnippetByteRange"]?.as?(String)
            parts = br.split(":")
            if parts.size == 2
              start_val = parts[0].to_i32?
              end_val = parts[1].to_i32?
              if start_val && end_val
                ranges << SnippetRange.new(
                  start_pointer: RangePointer.new(offset: start_val),
                  end_pointer: RangePointer.new(offset: end_val)
                )
              end
            end
          end

          if lr = s["SnippetLineRange"]?.as?(String)
            parts = lr.split(":")
            if parts.size == 2
              start_val = parts[0].to_i32?
              end_val = parts[1].to_i32?
              if start_val && end_val
                ranges << SnippetRange.new(
                  start_pointer: RangePointer.new(line_number: start_val),
                  end_pointer: RangePointer.new(line_number: end_val)
                )
              end
            end
          end

          snippet = Snippet.new(
            spdx_id: str_field(s, "SPDXID"),
            snippet_from_file: str_field(s, "SnippetFromFileSPDXID"),
            ranges: ranges,
            license_concluded: str_field(s, "SnippetLicenseConcluded"),
            copyright_text: str_field(s, "SnippetCopyrightText")
          )

          snippet.name = s["SnippetName"]?.as?(String)
          snippet.comment = s["SnippetComment"]?.as?(String)
          snippet.license_comments = s["SnippetLicenseComments"]?.as?(String)

          if li = s["LicenseInfoInSnippet"]?
            snippet.license_info_in_snippets = case li
                                               when Array(String) then li
                                               when String        then [li]
                                               else                    nil
                                               end
          end

          if at = s["SnippetAttributionText"]?
            snippet.attribution_texts = case at
                                        when Array(String) then at
                                        when String        then [at]
                                        else                    nil
                                        end
          end

          snippet
        end

        private def build_checksums(h : Hash(String, String | Array(String))) : Array(Checksum)?
          checksums = [] of Checksum
          {"PackageChecksum", "FileChecksum"}.each do |key|
            if value = h[key]?
              values = case value
                       when Array(String) then value
                       when String        then [value]
                       else                    next
                       end
              values.each do |v|
                if parsed = parse_checksum(v)
                  checksums << parsed
                end
              end
            end
          end
          checksums.empty? ? nil : checksums
        end

        private def parse_checksum(value : String) : Checksum?
          parts = value.split(":", 2)
          if parts.size == 2
            algo = parts[0].strip
            val = parts[1].strip
            begin
              Checksum.new(algorithm: ChecksumAlgorithm.from_string(algo), value: val)
            rescue
              nil
            end
          end
        end

        private def build_external_refs(p : Hash(String, String | Array(String))) : Array(ExternalRef)?
          refs = [] of ExternalRef
          if er = p["ExternalRef"]?
            values = case er
                     when Array(String) then er
                     when String        then [er]
                     else                    return nil
                     end

            values.each do |v|
              parts = v.split(/\s+/, 3)
              if parts.size >= 3
                refs << ExternalRef.new(
                  reference_category: ExternalRefCategory.from_string(parts[0]),
                  reference_type: parts[1],
                  reference_locator: parts[2]
                )
              end
            end
          end
          refs.empty? ? nil : refs
        end
      end
    end
  end
end
