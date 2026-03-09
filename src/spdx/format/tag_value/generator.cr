module Spdx
  module Format
    module TagValue
      class Generator
        def self.generate(doc : SpdxDocument) : String
          new(doc).generate
        end

        def initialize(@doc : SpdxDocument)
          @output = String::Builder.new
        end

        def generate : String
          write_document_header
          write_creation_info
          write_external_doc_refs
          write_packages
          write_files
          write_snippets
          write_extracted_licenses
          write_relationships
          write_annotations
          @output.to_s
        end

        private def write_document_header
          tag("SPDXVersion", @doc.spdx_version)
          tag("DataLicense", @doc.data_license)
          tag("SPDXID", @doc.spdx_id)
          tag("DocumentName", @doc.name)
          tag("DocumentNamespace", @doc.document_namespace)
          if comment = @doc.comment
            tag_multiline("DocumentComment", comment)
          end
          if describes = @doc.document_describes
            describes.each { |d| tag("DocumentDescribes", d) }
          end
        end

        private def write_creation_info
          ci = @doc.creation_info
          ci.creators.each { |c| tag("Creator", c) }
          tag("Created", ci.created)
          if v = ci.license_list_version
            tag("LicenseListVersion", v)
          end
          if c = ci.comment
            tag_multiline("CreatorComment", c)
          end
          @output << "\n"
        end

        private def write_external_doc_refs
          if refs = @doc.external_document_refs
            refs.each do |ref|
              @output << "ExternalDocumentRef: #{ref.external_document_id} #{ref.spdx_document} #{ref.checksum.algorithm}:#{ref.checksum.value}\n"
            end
            @output << "\n" unless refs.empty?
          end
        end

        private def write_packages
          if pkgs = @doc.packages
            pkgs.each do |pkg|
              @output << "##### Package: #{pkg.name}\n\n"
              tag("PackageName", pkg.name)
              tag("SPDXID", pkg.spdx_id)
              if v = pkg.version_info
                tag("PackageVersion", v)
              end
              if f = pkg.package_file_name
                tag("PackageFileName", f)
              end
              if s = pkg.supplier
                tag("PackageSupplier", s)
              end
              if o = pkg.originator
                tag("PackageOriginator", o)
              end
              tag("PackageDownloadLocation", pkg.download_location)
              if fa = pkg.files_analyzed
                tag("FilesAnalyzed", fa.to_s)
              end
              if vc = pkg.package_verification_code
                value = vc.value
                if excl = vc.excluded_files
                  value += " (excludes: #{excl.join(", ")})"
                end
                tag("PackageVerificationCode", value)
              end
              if checksums = pkg.checksums
                checksums.each do |cs|
                  tag("PackageChecksum", "#{cs.algorithm}: #{cs.value}")
                end
              end
              if hp = pkg.homepage
                tag("PackageHomePage", hp)
              end
              if si = pkg.source_info
                tag_multiline("PackageSourceInfo", si)
              end
              tag("PackageLicenseConcluded", pkg.license_concluded)
              if lif = pkg.license_info_from_files
                lif.each { |l| tag("PackageLicenseInfoFromFiles", l) }
              end
              tag("PackageLicenseDeclared", pkg.license_declared)
              if lc = pkg.license_comments
                tag_multiline("PackageLicenseComments", lc)
              end
              tag("PackageCopyrightText", pkg.copyright_text)
              if s = pkg.summary
                tag_multiline("PackageSummary", s)
              end
              if d = pkg.description
                tag_multiline("PackageDescription", d)
              end
              if c = pkg.comment
                tag_multiline("PackageComment", c)
              end
              if refs = pkg.external_refs
                refs.each do |ref|
                  tag("ExternalRef", "#{ref.reference_category} #{ref.reference_type} #{ref.reference_locator}")
                  if c = ref.comment
                    tag_multiline("ExternalRefComment", c)
                  end
                end
              end
              if at = pkg.attribution_texts
                at.each { |a| tag_multiline("PackageAttributionText", a) }
              end
              if pp = pkg.primary_package_purpose
                tag("PrimaryPackagePurpose", pp.to_s)
              end
              if rd = pkg.release_date
                tag("ReleaseDate", rd)
              end
              if bd = pkg.built_date
                tag("BuiltDate", bd)
              end
              if vd = pkg.valid_until_date
                tag("ValidUntilDate", vd)
              end
              @output << "\n"
            end
          end
        end

        private def write_files
          if files = @doc.files
            files.each do |f|
              tag("FileName", f.file_name)
              tag("SPDXID", f.spdx_id)
              if types = f.file_types
                types.each { |t| tag("FileType", t.to_s) }
              end
              if checksums = f.checksums
                checksums.each do |cs|
                  tag("FileChecksum", "#{cs.algorithm}: #{cs.value}")
                end
              end
              tag("LicenseConcluded", f.license_concluded)
              if li = f.license_info_in_files
                li.each { |l| tag("LicenseInfoInFile", l) }
              end
              tag("FileCopyrightText", f.copyright_text)
              if c = f.comment
                tag_multiline("FileComment", c)
              end
              if n = f.notice_text
                tag_multiline("FileNotice", n)
              end
              if contribs = f.file_contributors
                contribs.each { |c| tag("FileContributor", c) }
              end
              if at = f.attribution_texts
                at.each { |a| tag_multiline("FileAttributionText", a) }
              end
              @output << "\n"
            end
          end
        end

        private def write_snippets
          if snippets = @doc.snippets
            snippets.each do |s|
              tag("SnippetSPDXID", s.spdx_id)
              tag("SnippetFromFileSPDXID", s.snippet_from_file)
              s.ranges.each do |r|
                if offset_start = r.start_pointer.offset
                  if offset_end = r.end_pointer.offset
                    tag("SnippetByteRange", "#{offset_start}:#{offset_end}")
                  end
                end
                if line_start = r.start_pointer.line_number
                  if line_end = r.end_pointer.line_number
                    tag("SnippetLineRange", "#{line_start}:#{line_end}")
                  end
                end
              end
              tag("SnippetLicenseConcluded", s.license_concluded)
              if li = s.license_info_in_snippets
                li.each { |l| tag("LicenseInfoInSnippet", l) }
              end
              tag("SnippetCopyrightText", s.copyright_text)
              if n = s.name
                tag("SnippetName", n)
              end
              if c = s.comment
                tag_multiline("SnippetComment", c)
              end
              if lc = s.license_comments
                tag_multiline("SnippetLicenseComments", lc)
              end
              if at = s.attribution_texts
                at.each { |a| tag_multiline("SnippetAttributionText", a) }
              end
              @output << "\n"
            end
          end
        end

        private def write_extracted_licenses
          if licenses = @doc.extracted_licensing_infos
            licenses.each do |lic|
              tag("LicenseID", lic.license_id)
              tag_multiline("ExtractedText", lic.extracted_text)
              if n = lic.name
                tag("LicenseName", n)
              end
              if refs = lic.see_alsos
                refs.each { |r| tag("LicenseCrossReference", r) }
              end
              if c = lic.comment
                tag_multiline("LicenseComment", c)
              end
              @output << "\n"
            end
          end
        end

        private def write_relationships
          if rels = @doc.relationships
            rels.each do |rel|
              tag("Relationship", "#{rel.spdx_element_id} #{rel.relationship_type} #{rel.related_spdx_element}")
              if c = rel.comment
                tag_multiline("RelationshipComment", c)
              end
            end
            @output << "\n" unless rels.empty?
          end
        end

        private def write_annotations
          if anns = @doc.annotations
            anns.each do |ann|
              tag("Annotator", ann.annotator)
              tag("AnnotationDate", ann.annotation_date)
              tag_multiline("AnnotationComment", ann.comment)
              tag("AnnotationType", ann.annotation_type.to_s)
              if id = ann.spdx_element_id
                tag("SPDXREF", id)
              end
              @output << "\n"
            end
          end
        end

        private def tag(name : String, value : String)
          @output << name << ": " << value << "\n"
        end

        private def tag_multiline(name : String, value : String)
          if value.includes?("\n")
            @output << name << ": <text>" << value << "</text>\n"
          else
            @output << name << ": " << value << "\n"
          end
        end
      end
    end
  end
end
