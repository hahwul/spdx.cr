require "../../spec_helper"

describe Spdx::SpdxDocument do
  it "creates a minimal valid document" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "MIT",
        license_declared: "MIT",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.relationships = [
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "SPDXRef-Package"
      ),
    ]
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.valid?.should be_true
  end

  it "validates required fields" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.valid?.should be_false
    doc.validate.should contain("spdxVersion is required")
  end

  it "validates data license must be CC0-1.0" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "MIT",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.should contain("dataLicense must be 'CC0-1.0'")
  end

  it "validates documentNamespace must be a valid URI" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "not-a-uri",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.should contain("documentNamespace must be a valid URI")
  end

  it "validates creator format" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["invalid-creator"]
      )
    )
    doc.validate.any?(&.includes?("Tool:")).should be_true
  end

  it "validates created date ISO 8601 format" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01",
        creators: ["Tool: test"]
      )
    )
    doc.validate.any?(&.includes?("ISO 8601")).should be_true
  end

  it "validates DESCRIBES relationship is required" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.any?(&.includes?("must declare what it describes")).should be_true
  end

  it "accepts documentDescribes in place of a DESCRIBES relationship" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "MIT",
        license_declared: "MIT",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.document_describes = ["SPDXRef-Package"]
    doc.validate.any?(&.includes?("must declare what it describes")).should be_false
  end

  it "flags a relationship referencing an undefined SPDXID" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.relationships = [
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "SPDXRef-Nope"
      ),
    ]
    doc.validate.any?(&.includes?("undefined element 'SPDXRef-Nope'")).should be_true
  end

  it "accepts NOASSERTION and external DocumentRef relationship targets" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.external_document_refs = [
      Spdx::ExternalDocumentRef.new(
        external_document_id: "DocumentRef-ext",
        spdx_document: "https://example.org/ext",
        checksum: Spdx::Checksum.new(algorithm: Spdx::ChecksumAlgorithm::SHA1, value: "0" * 40)
      ),
    ]
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.relationships = [
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "NOASSERTION"
      ),
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "DocumentRef-ext:SPDXRef-Thing"
      ),
    ]
    doc.validate.none?(&.includes?("undefined element")).should be_true
  end

  it "flags duplicate SPDXIDs" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Dup", name: "A",
        download_location: "https://example.org/a",
        license_concluded: "MIT", license_declared: "MIT",
        copyright_text: "c"
      ).tap(&.files_analyzed=(false)),
      Spdx::Package.new(
        spdx_id: "SPDXRef-Dup", name: "B",
        download_location: "https://example.org/b",
        license_concluded: "MIT", license_declared: "MIT",
        copyright_text: "c"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.document_describes = ["SPDXRef-Dup"]
    doc.validate.any?(&.includes?("duplicate SPDXID 'SPDXRef-Dup'")).should be_true
  end

  it "treats packageVerificationCode as optional, but forbids it when filesAnalyzed is false" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    pkg = Spdx::Package.new(
      spdx_id: "SPDXRef-Package",
      name: "TestPkg",
      download_location: "https://example.org/pkg"
    )
    doc.packages = [pkg]
    doc.document_describes = ["SPDXRef-Package"]
    # SPDX 2.3 §7.9 (Table 21): Required: No, 0..1 when FilesAnalyzed is
    # true or omitted; and licenseConcluded/licenseDeclared/copyrightText are
    # 0..1 too (§7.13, §7.15, §7.17).
    doc.validate.should be_empty

    pkg.files_analyzed = false
    pkg.package_verification_code = Spdx::PackageVerificationCode.new("d6a770ba38583ed4bb4525bd96e50461655d2758")
    doc.validate.should eq(["packages[0].packageVerificationCode must be omitted when filesAnalyzed is false"])

    # SPDX 2.3 §7.14 (Table 26): 0..0 (must be omitted) if FilesAnalyzed is false.
    pkg.package_verification_code = nil
    pkg.license_info_from_files = ["MIT"]
    doc.validate.should eq(["packages[0].licenseInfoFromFiles must be omitted when filesAnalyzed is false"])

    # §7.8: if false, the package shall not contain any files.
    pkg.license_info_from_files = nil
    pkg.has_files = ["SPDXRef-File"]
    doc.validate.should contain("packages[0].hasFiles must be omitted when filesAnalyzed is false")
  end

  it "requires a SHA1 checksum on every file" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    file = Spdx::FileInfo.new(spdx_id: "SPDXRef-File", file_name: "./a.c")
    doc.files = [file]
    doc.document_describes = ["SPDXRef-File"]
    # SPDX 2.3 §8.4 (Table 39): Required, 1..1 for SHA1.
    doc.validate.should eq(["files[0].checksums must include a SHA1 checksum"])

    file.checksums = [Spdx::Checksum.new(Spdx::ChecksumAlgorithm::SHA256, "ab")]
    doc.validate.should eq(["files[0].checksums must include a SHA1 checksum"])

    file.checksums.not_nil! << Spdx::Checksum.new(Spdx::ChecksumAlgorithm::SHA1, "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    doc.validate.should be_empty
  end

  it "serializes to JSON" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    json = doc.to_json
    parsed = Spdx::SpdxDocument.from_json(json)
    parsed.spdx_version.should eq("SPDX-2.3")
    parsed.name.should eq("Test")
  end

  it "flags an invalid SPDX license expression in a package field" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "NOT-A-LICENSE AND ALSO-FAKE",
        license_declared: "garbage(((",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    errors = doc.validate
    errors.any?(&.includes?("licenseConcluded")).should be_true
    errors.any?(&.includes?("licenseDeclared")).should be_true
  end

  it "accepts NOASSERTION in a package license field" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "NOASSERTION",
        license_declared: "MIT OR Apache-2.0",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.validate.none?(&.includes?("license")).should be_true
  end

  it "rejects a documentNamespace containing a '#' fragment delimiter" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test#fragment",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.any?(&.includes?("'#' fragment delimiter")).should be_true
  end

  it "validates hasExtractedLicensingInfos entries" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.extracted_licensing_infos = [
      Spdx::ExtractedLicensingInfo.new(license_id: "not-a-license-ref", extracted_text: "text"),
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-a", extracted_text: ""),
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-a", extracted_text: "text"),
    ]

    errors = doc.validate
    errors.any?(&.includes?("licenseId must be of the form 'LicenseRef-[idstring]'")).should be_true
    errors.any?(&.includes?("extractedText is required")).should be_true
    errors.any?(&.includes?("duplicates 'LicenseRef-a'")).should be_true
  end

  it "accepts well-formed hasExtractedLicensingInfos entries" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.extracted_licensing_infos = [
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-custom-1", extracted_text: "text"),
    ]
    doc.validate.none?(&.includes?("hasExtractedLicensingInfos")).should be_true
  end

  it "accepts a 'created' timestamp with fractional seconds" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00.123Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.none?(&.includes?("ISO 8601")).should be_true
  end

  # SPDX 2.3 clause 11.1 / the 2.3 JSON schema's relationshipType enum.
  it "flags relationship types that are not in SPDX 2.3" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(created: "2024-01-01T00:00:00Z", creators: ["Tool: test"])
    )
    doc.relationships = [
      Spdx::Relationship.new(spdx_element_id: "SPDXRef-DOCUMENT", relationship_type: Spdx::RelationshipType::DESCRIBES, related_spdx_element: "NOASSERTION"),
      Spdx::Relationship.new(spdx_element_id: "SPDXRef-DOCUMENT", relationship_type: Spdx::RelationshipType::AFFECTS, related_spdx_element: "NOASSERTION"),
    ]
    doc.validate.should eq(["relationships[1].relationshipType 'AFFECTS' is not an SPDX 2.3 relationship type"])
  end

  it "reports invalid UTF-8 instead of raising, for a document built in code" do
    bad = String.new(Bytes[0x78, 0xff])
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3", data_license: "CC0-1.0", spdx_id: "SPDXRef-DOCUMENT",
      name: bad, document_namespace: "https://example.org/#{bad}",
      creation_info: Spdx::CreationInfo.new(created: bad, creators: [bad])
    )
    doc.packages = [Spdx::Package.new(spdx_id: bad, name: "p", download_location: "NOASSERTION", license_concluded: bad)]
    doc.files = [Spdx::FileInfo.new(spdx_id: bad, file_name: "f")]
    doc.snippets = [Spdx::Snippet.new(spdx_id: bad, snippet_from_file: "f", ranges: [] of Spdx::SnippetRange)]
    doc.extracted_licensing_infos = [Spdx::ExtractedLicensingInfo.new(license_id: bad, extracted_text: "t")]
    doc.relationships = [Spdx::Relationship.new(spdx_element_id: bad, relationship_type: Spdx::RelationshipType::DESCRIBES, related_spdx_element: bad)]

    errors = doc.validate
    errors.should contain("document contains invalid UTF-8 (SPDX documents must be UTF-8)")
    errors.should contain("documentNamespace must be a valid URI")
    errors.should contain("creationInfo.creators[0] must start with 'Tool:', 'Organization:', or 'Person:'")
    errors.should contain("packages[0].SPDXID format invalid")
    errors.should contain("packages[0].licenseConcluded: invalid SPDX license expression (Expression is not valid UTF-8)")
    errors.should contain("files[0].SPDXID format invalid")
    errors.should contain("snippets[0].SPDXID format invalid")
    errors.should contain("hasExtractedLicensingInfos[0].licenseId must be of the form 'LicenseRef-[idstring]'")
  end

  it "reports invalid UTF-8 in a field that has no format check" do
    json = %({"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT","name":"x\xFF","documentNamespace":"https://example.org/x","creationInfo":{"created":"2024-01-01T00:00:00Z","creators":["Tool: t"]},"documentDescribes":["SPDXRef-DOCUMENT"]})
    doc = Spdx::SpdxDocument.from_json(json)
    doc.validate.should eq(["document contains invalid UTF-8 (SPDX documents must be UTF-8)"])
  end
end
