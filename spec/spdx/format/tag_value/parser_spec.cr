require "../../../spec_helper"

describe Spdx::Format::TagValue::Parser do
  it "parses example Tag-Value file" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.name.should eq("Example")
    doc.document_namespace.should eq("https://example.org/example")
  end

  it "parses creation info" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    doc.creation_info.created.should eq("2024-01-01T00:00:00Z")
    doc.creation_info.creators.size.should eq(2)
    doc.creation_info.license_list_version.should eq("3.22")
  end

  it "parses packages" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    pkgs = doc.packages.not_nil!
    pkgs.size.should eq(1)
    pkgs[0].name.should eq("Example Package")
    pkgs[0].version_info.should eq("1.0.0")
    pkgs[0].license_concluded.should eq("Apache-2.0")
  end

  it "parses files" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    files = doc.files.not_nil!
    files.size.should eq(1)
    files[0].file_name.should eq("./src/main.cr")
    files[0].spdx_id.should eq("SPDXRef-File1")
  end

  it "parses relationships" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    rels = doc.relationships.not_nil!
    rels.size.should eq(2)
    rels[0].relationship_type.should eq(Spdx::RelationshipType::DESCRIBES)
    rels[0].spdx_element_id.should eq("SPDXRef-DOCUMENT")
  end

  it "parses extracted licensing infos with multiline text" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    infos = doc.extracted_licensing_infos.not_nil!
    infos.size.should eq(1)
    infos[0].license_id.should eq("LicenseRef-custom-1")
    infos[0].extracted_text.should contain("multiple lines")
  end

  it "parses snippets" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    snippets = doc.snippets.not_nil!
    snippets.size.should eq(1)
    snippets[0].spdx_id.should eq("SPDXRef-Snippet1")
    snippets[0].name.should eq("Main snippet")
  end

  it "parses external document refs" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    refs = doc.external_document_refs.not_nil!
    refs.size.should eq(1)
    refs[0].external_document_id.should eq("DocumentRef-ext1")
  end

  it "parses annotations" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    # `SPDXREF: SPDXRef-Package` — owned by the package, as in the JSON schema.
    doc.annotations.should be_nil
    anns = doc.packages.not_nil![0].annotations.not_nil!
    anns.size.should eq(1)
    anns[0].annotation_type.should eq(Spdx::AnnotationType::REVIEW)
    anns[0].annotator.should eq("Person: Jane Doe (jane@example.org)")
  end

  it "parses an ExternalDocumentRef whose checksum uses the canonical spacing" do
    # SPDX 2.3 §6.6 writes the trailing checksum as `SHA1: d6a770ba...`.
    input = <<-SPDX
      SPDXVersion: SPDX-2.3
      DataLicense: CC0-1.0
      SPDXID: SPDXRef-DOCUMENT
      DocumentName: Example
      DocumentNamespace: https://example.org/example
      Creator: Tool: example
      Created: 2024-01-01T00:00:00Z
      ExternalDocumentRef: DocumentRef-spdx-tool-1.2 https://spdx.org/spdxdocs/spdx-tools-v1.2 SHA1: d6a770ba38583ed4bb4525bd96e50461655d2759
      SPDX

    ref = Spdx::Format::TagValue::Parser.parse(input).external_document_refs.not_nil![0]
    ref.external_document_id.should eq("DocumentRef-spdx-tool-1.2")
    ref.checksum.algorithm.should eq(Spdx::ChecksumAlgorithm::SHA1)
    ref.checksum.value.should eq("d6a770ba38583ed4bb4525bd96e50461655d2759")
  end

  it "raises FormatError on an unknown AnnotationType instead of silently using OTHER" do
    input = <<-SPDX
      SPDXVersion: SPDX-2.3
      DataLicense: CC0-1.0
      SPDXID: SPDXRef-DOCUMENT
      DocumentName: Example
      DocumentNamespace: https://example.org/example
      Creator: Tool: example
      Created: 2024-01-01T00:00:00Z
      Annotator: Person: Jane Doe
      AnnotationDate: 2024-01-01T00:00:00Z
      AnnotationComment: c
      AnnotationType: BOGUS
      SPDX

    expect_raises(Spdx::FormatError, "Unknown annotation type: BOGUS") do
      Spdx::Format::TagValue::Parser.parse(input)
    end
  end

  it "generates Tag-Value from parsed document" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    output = Spdx::Format::TagValue::Generator.generate(doc)
    output.should contain("SPDXVersion: SPDX-2.3")
    output.should contain("PackageName: Example Package")
    output.should contain("Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Package")
  end

  describe "official SPDX 2.3 tag-value constructs" do
    header = <<-SPDX
      SPDXVersion: SPDX-2.3
      DataLicense: CC0-1.0
      SPDXID: SPDXRef-DOCUMENT
      DocumentName: Example
      DocumentNamespace: https://example.org/example
      Creator: Tool: example
      Created: 2024-01-01T00:00:00Z

      SPDX

    it "parses a PackageVerificationCode with and without the excludes keyword" do
      # SPDXTagExample-v2.3.spdx writes `<code>(./package.spdx)`; §7.9
      # writes `<code> (excludes: ./package.spdx)`.
      {"d6a770ba38583ed4bb4525bd96e50461655d2758(./package.spdx)",
       "d6a770ba38583ed4bb4525bd96e50461655d2758 (excludes: ./package.spdx)"}.each do |value|
        doc = Spdx::Format::TagValue::Parser.parse(header + "PackageName: p\nSPDXID: SPDXRef-P\nPackageVerificationCode: #{value}\n")
        vc = doc.packages.not_nil![0].package_verification_code.not_nil!
        vc.value.should eq("d6a770ba38583ed4bb4525bd96e50461655d2758")
        vc.excluded_files.should eq(["./package.spdx"])
      end
    end

    it "round-trips several excluded files" do
      doc = Spdx::Format::TagValue::Parser.parse(header + "PackageName: p\nSPDXID: SPDXRef-P\n")
      doc.packages.not_nil![0].package_verification_code =
        Spdx::PackageVerificationCode.new("d6a770ba38583ed4bb4525bd96e50461655d2758", ["./a.spdx", "./b.spdx"])
      reparsed = Spdx::Format::TagValue::Parser.parse(Spdx::Format::TagValue::Generator.generate(doc))
      reparsed.packages.not_nil![0].package_verification_code.not_nil!.excluded_files.should eq(["./a.spdx", "./b.spdx"])
    end

    it "attaches ExternalRefComment to its ExternalRef" do
      input = header + <<-SPDX
        PackageName: p
        SPDXID: SPDXRef-P
        ExternalRef: SECURITY cpe23Type cpe:2.3:a:pivotal_software:spring_framework:4.1.0:*:*:*:*:*:*:*
        ExternalRef: OTHER LocationRef-acmeforge acmecorp/acmenator/4.1.3-alpha
        ExternalRefComment: <text>This is the
        external ref for Acme</text>
        SPDX
      refs = Spdx::Format::TagValue::Parser.parse(input).packages.not_nil![0].external_refs.not_nil!
      refs[0].comment.should be_nil
      refs[1].comment.should eq("This is the\nexternal ref for Acme")
    end

    it "routes multi-line values through the same tag handling as single-line ones" do
      input = header + <<-SPDX
        PackageName: p
        SPDXID: SPDXRef-P
        PackageAttributionText: <text>first
        notice</text>
        PackageAttributionText: <text>second
        notice</text>
        Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-P
        RelationshipComment: <text>multi
        line</text>
        SPDX
      doc = Spdx::Format::TagValue::Parser.parse(input)
      doc.packages.not_nil![0].attribution_texts.should eq(["first\nnotice", "second\nnotice"])
      doc.relationships.not_nil![0].comment.should eq("multi\nline")
    end

    it "parses ReleaseDate, BuiltDate and ValidUntilDate" do
      input = header + <<-SPDX
        PackageName: p
        SPDXID: SPDXRef-P
        ReleaseDate: 2012-01-29T18:30:22Z
        BuiltDate: 2011-01-29T18:30:22Z
        ValidUntilDate: 2014-01-29T18:30:22Z
        SPDX
      pkg = Spdx::Format::TagValue::Parser.parse(input).packages.not_nil![0]
      pkg.release_date.should eq("2012-01-29T18:30:22Z")
      pkg.built_date.should eq("2011-01-29T18:30:22Z")
      pkg.valid_until_date.should eq("2014-01-29T18:30:22Z")
    end

    it "parses file LicenseComments" do
      input = header + "FileName: ./f\nSPDXID: SPDXRef-F\nLicenseComments: This license is used by Jena\n"
      doc = Spdx::Format::TagValue::Parser.parse(input)
      doc.files.not_nil![0].license_comments.should eq("This license is used by Jena")
      Spdx::Format::TagValue::Generator.generate(doc).should contain("LicenseComments: This license is used by Jena")
    end

    it "points snippet ranges at SnippetFromFileSPDXID (JSON schema requires reference)" do
      input = header + <<-SPDX
        SnippetSPDXID: SPDXRef-S
        SnippetFromFileSPDXID: SPDXRef-F
        SnippetByteRange: 310:420
        SnippetLineRange: 5:23
        SPDX
      ranges = Spdx::Format::TagValue::Parser.parse(input).snippets.not_nil![0].ranges
      ranges.flat_map { |r| [r.start_pointer.reference, r.end_pointer.reference] }.uniq!.should eq(["SPDXRef-F"])
    end

    it "nests element annotations so the JSON output carries no spdxElementId" do
      input = header + <<-SPDX
        PackageName: p
        SPDXID: SPDXRef-P

        Annotator: Person: Jane Doe ()
        AnnotationDate: 2010-01-29T18:30:22Z
        AnnotationComment: Document level annotation
        AnnotationType: OTHER
        SPDXREF: SPDXRef-DOCUMENT

        Annotator: Person: Package Commenter
        AnnotationDate: 2011-01-29T18:30:22Z
        AnnotationComment: Package level annotation
        AnnotationType: OTHER
        SPDXREF: SPDXRef-P
        SPDX
      doc = Spdx::Format::TagValue::Parser.parse(input)
      doc.annotations.not_nil!.map(&.comment).should eq(["Document level annotation"])
      doc.packages.not_nil![0].annotations.not_nil!.map(&.comment).should eq(["Package level annotation"])

      json = Spdx::Format::Json::Generator.generate(doc)
      json.should_not contain("spdxElementId") # the document has no relationships
      # and back to tag-value with each SPDXREF intact
      output = Spdx::Format::TagValue::Generator.generate(Spdx::Format::Json::Parser.parse(json))
      output.should contain("SPDXREF: SPDXRef-DOCUMENT")
      output.should contain("SPDXREF: SPDXRef-P")
    end
  end
end
